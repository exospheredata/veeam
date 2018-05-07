# Cookbook Name:: veeam
# Resource:: upgrade
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 1.0.0
# Date:: 2018-04-29
#
# Copyright (c) 2016 Exosphere Data LLC, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default_action :install

property :build, String, name_property: true

property :package_url, String
property :package_checksum, String

property :version, String
property :keep_media, [TrueClass, FalseClass], default: false
property :auto_reboot, [TrueClass, FalseClass], default: true

property :package_name, String # Future Property
property :share_path, String   # Future Property

# => We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)
::Chef::Provider.send(:include, Veeam::Helper)

action :install do
  # => Verify that the node passes the OS version checks.
  check_os_version(node)

  # => Call the Veeam::Helper to find the correct URL based on the build or version of the Veeam
  # => Backup and Replication edition passed as an attribute.
  unless new_resource.package_url
    new_resource.build = new_resource.version if new_resource.build.nil?
    # => If there is no url, no version, and no build then what are we doing here?
    raise ArgumentError, 'You must provide a package URL or choose a valid build' unless new_resource.build
    new_resource.package_url = find_update_url(new_resource.build)
    new_resource.package_checksum = find_update_checksum(new_resource.build)
    # => Halt this process now.  There is no URL for the package.
    raise ArgumentError, 'You must provide a package URL or choose a valid build' unless new_resource.package_url
    Chef::Log.debug("Dynamically found the Build Upgrade Url: #{new_resource.package_url}")
  end

  # => So without a build we will have a hard time determining how to upgrade.  Since we have the update url
  # => we can extract the build from this.
  new_resource.build = /(\d+.\d+.\d+.\d+)/.match(new_resource.package_url.split('/')[-1]).captures[0] unless new_resource.build

  # => We need to determine the actual build of installed Veeam Software.  Since there are three main packages
  # => we will need to iterate through their possible locations.
  current_build = nil
  ['Veeam Backup & Replication Console', 'Veeam Backup & Replication Server', 'Veeam Backup & Replication Catalog'].each do |package|
    current_build = find_current_veeam_version(package)
    break unless current_build.nil?
  end
  # => If there is no currently installed software then we should gracefully handle this
  # => by returning false
  return false unless current_build

  # => If the current installed version is greater or equal to the requested build version
  # => then return false to notify everyone that we are up to date.
  return false unless Gem::Version.new(new_resource.build) > Gem::Version.new(current_build)

  converge_by "Upgrading Veeam Installation to Version #{new_resource.build}" do
    # We need to verify that .NET Framework 4.5.2 or higher has been installed on the machine
    raise 'The Veeam Backup and Replication Server requires that Microsoft .NET Framework 4.5.2 or higher be installed.  Please install the Veeam pre-requisites' if find_current_dotnet < 379893

    package_save_dir = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'package'))

    # This will only create the directory if it does not exist which is likely the case if we have
    # never performed a remote_file install.
    directory package_save_dir do
      action :create
    end

    # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
    # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
    # This is easy to handle as long as we add a method to check for the file base type.

    Chef::Log.debug('Downloading Veeam Backup and Replication software via URL')
    package_name = new_resource.package_url.split('/').last
    %w(& $).each do |special_char|
      package_name = package_name.gsub(special_char, '_')
    end
    package_type = ::File.extname(package_name)
    installer_file_name = win_friendly_path(::File.join(package_save_dir, package_name))

    install_media_path = if package_type == '.iso'
                           iso_installer(installer_file_name, new_resource)
                         else
                           extract_installer(installer_file_name, new_resource)
                         end

    ruby_block 'Perform Upgrade Procedure' do
      block do
        install_media_path = get_media_installer_location(installer_file_name) if package_type == '.iso'
        perform_server_upgrade(install_media_path)
      end
    end

    unmount_installer(installer_file_name)

    # If the 'keep_media' property is True, we should report our success but skip the file deletion code below.
    return if new_resource.keep_media

    # Since the property 'keep_media' was set to false, we will need to remove it

    # We will want to remove the tmp downloaded file later to save space
    file installer_file_name do
      backup false
      action :delete
    end
  end
end

action_class do
  def whyrun_supported?
    true
  end

  def perform_server_upgrade(install_media_path)
    Chef::Log.debug 'Upgrading Veeam Backup server service... begin'
    # VBR Service Configuration
    cmd_str = <<~EOH
      function Sort-Naturally
      # Great Sorting Function
      # https://stackoverflow.com/a/48333846
      {
          PARAM(
              [string[]]$files
          )

      Add-Type -TypeDefinition @'
      using System;
      using System.Collections;
      using System.Collections.Generic;
      using System.Runtime.InteropServices;

      namespace NaturalSort {
          public static class NaturalSort
          {
              [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
              public static extern int StrCmpLogicalW(string psz1, string psz2);

              public static System.Collections.ArrayList Sort(System.Collections.ArrayList foo)
              {
                  foo.Sort(new NaturalStringComparer());
                  return foo;
              }
          }

          public class NaturalStringComparer : IComparer
          {
              public int Compare(object x, object y)
              {
                  return NaturalSort.StrCmpLogicalW(x.ToString(), y.ToString());
              }
          }
      }
      '@

          return [NaturalSort.NaturalSort]::Sort($files)
      }
      $all_veeam_updates = (Get-ChildItem -Path "#{install_media_path}\\Updates" -ErrorAction SilentlyContinue | %{$_.Name})
      if($all_veeam_updates){
        $sorted_files = (Sort-Naturally -files $all_veeam_updates) # Grab the most recent Update
        $latest_veeam_updates = if($sorted_files.count -gt 1){ $sorted_files[-1] }else{ $sorted_files }
        $veeam_backup_server_installer = ( "#{install_media_path}\\Updates\\$latest_veeam_updates")
        $log_file = $latest_veeam_updates.replace(".exe",".log")
        Write-Host ($veeam_backup_server_installer + ' /silent /norestart /log #{::Chef::Config[:file_cache_path]}\\' + $log_file + ' VBR_AUTO_UPGRADE=1')
        $output = (Start-Process -FilePath $veeam_backup_server_installer -ArgumentList $(' /silent /noreboot /log #{::Chef::Config[:file_cache_path]}\\' + $log_file + ' VBR_AUTO_UPGRADE=1') -Wait -Passthru -ErrorAction Stop)
        switch ( $output.ExitCode){
          0 { Write-Host "Update Completed Successfully" }
          3010 { Write-Host "Need Reboot"}
          default {
            throw ("The updates failed with ExitCode [{0}].  The package is {1}" -f $output.ExitCode, $veeam_backup_server_installer )
          }
        }
      } else {
        Write-Host 'No update'
      }
    EOH
    output = validate_powershell_out(cmd_str, timeout: 1800)
    if output == 'No update'
      Chef::Log.warn 'Upgrade Skipped as no Upgrade files found'
      return false
    end

    reboot 'Required Reboot after Veeam Upgrade' do
      action :request_reboot
      only_if { reboot_pending? }
      only_if { new_resource.auto_reboot }
    end
    Chef::Log.debug 'Upgrading Veeam Backup server service... success'
  end
end
