# Cookbook Name:: veeam
# Resource:: prerequisites
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.2.0
# Date:: 2017-02-13
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

property :package_name, String
property :share_path, String

property :package_url, String
property :package_checksum, String

property :version, String, required: true
property :install_sql, [TrueClass, FalseClass], default: false

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)

action :install do
  veeam = Veeam::Helper # Library of helper methods
  veeam.check_os_version(node)

  # Call the Veeam::Helper to find the correct URL based on the version of the Veeam Backup and Recovery edition passed
  # as an attribute.
  unless new_resource.package_url
    new_resource.package_url = veeam.find_package_url(new_resource.version)
    new_resource.package_checksum = veeam.find_package_checksum(new_resource.version)
  end

  # Halt this process now.  There is no URL for the package.
  raise ArgumentError, 'You must provide a package URL or choose a valid version' unless new_resource.package_url

  # Determine if all of the Veeam pre-requisites are installed and if so, then skip the processing.
  prerequisites_list = []
  installed_prerequisites = []
  prerequisites_hash = veeam.prerequisites_list(new_resource.version)

  prerequisites_hash.each do |item, prerequisites|
    package_name = prerequisites.map { |k, _v| k }.join(',')
    unless item == 'SQL' && new_resource.install_sql == false
      prerequisites_list.push(package_name)
      installed_prerequisites.push(package_name) if is_package_installed?(package_name)
    end
  end

  # Compare the required Prerequisites with those installed.  If all are installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  return false if (prerequisites_list - installed_prerequisites).empty? && find_current_dotnet >= 379893

  package_save_dir = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'package'))

  # This will only create the directory if it does not exist which is likely the case if we have
  # never performed a remote_file install.
  directory package_save_dir do
    action :create
  end

  # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
  # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
  # This is easy to handle as long as we add a method to check for the file base type.

  Chef::Log.debug('Downloading Veeam Backup and Recovery software via URL')
  package_name = new_resource.package_url.split('/').last
  installer_file_name = win_friendly_path(::File.join(package_save_dir, package_name))
  download_installer(installer_file_name)

  install_dotnet(installer_file_name)
  install_sql_tools(installer_file_name)
  install_sql_express(installer_file_name) if new_resource.install_sql

  # Dismount the ISO if it is mounted
  unmount_installer(installer_file_name)

  # Hey these are pre-requisites so we should probably just keep the media, right?  For this reason, I removed
  # the resource block to delete the media
end

action_class do
  def whyrun_supported?
    true
  end

  def find_current_dotnet
    installed_version = nil
    installed_version_reg_key = registry_get_values('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full')
    unless installed_version_reg_key.nil?
      installed_version_reg_key.each do |key|
        installed_version = key[:data] if key[:name] == 'Release'
      end
    end
    installed_version.nil? ? 0 : installed_version
  end

  def validate_powershell_out(script)
    # This seemed like the DRYest way to handle the output handling from PowerShell.
    cmd = powershell_out(script)
    # Check powershell output
    raise cmd.inspect if cmd.stderr != ''
    cmd.stdout.chop
  end

  def download_installer(downloaded_file_name)
    # Download the Installer media
    remote_file downloaded_file_name do
      source new_resource.package_url
      checksum new_resource.package_checksum
      provider Chef::Provider::RemoteFile
      use_conditional_get true # this should allow us to prevent duplicate downloads
      action :create
    end

    # Mounting the Veeam backup ISO.
    powershell_script 'Load Veeam media' do
      code <<-EOH
        Mount-DiskImage -ImagePath "#{downloaded_file_name}"
      EOH
      guard_interpreter :powershell_script
      not_if "[boolean] (Get-DiskImage -ImagePath '#{downloaded_file_name}').DevicePath"
    end
  end

  def unmount_installer(downloaded_file_name)
    # Unmount the Veeam backup ISO.
    powershell_script 'Dismount Veeam media' do
      code <<-EOH
        Dismount-DiskImage -ImagePath "#{downloaded_file_name}"
      EOH
      guard_interpreter :powershell_script
      only_if "[boolean] (Get-DiskImage -ImagePath '#{downloaded_file_name}').DevicePath"
    end
  end

  def get_media_installer_location(downloaded_file_name)
    # When downloading and mounting the ISO, we need to track back to the Drive Letter.  This method will handle
    # the look-up and keep the logic out of the main installation code.
    Chef::Log.debug 'Searching for the Veeam installation media Drive Letter...'
    cmd_str = <<-EOH
      $DriveLetter = (Get-DiskImage -ImagePath '#{downloaded_file_name}' | Get-Volume).DriveLetter;
      if ( [string]::IsNullOrEmpty($DriveLetter) ){ throw 'The ISO did not mount and we have no idea why.' }
      return ( $DriveLetter +':\' )
    EOH
    output = validate_powershell_out(cmd_str)
    raise ArgumentError, 'Unable to find the Veeam installation media' unless output
    Chef::Log.debug "Found the Veeam installation media at Drive Letter [#{output}]"
    output
  end

  def install_dotnet(downloaded_file_name)
    return 'Already installed' if find_current_dotnet >= 379893
    reboot 'DotNet Install Complete' do
      reason 'Reboot required after an installation of .NET Framework'
      action :nothing
    end

    ruby_block 'Install the .NET 4.5.2' do
      block do
        install_media_path = get_media_installer_location(downloaded_file_name)
        windows_package 'Microsoft .NET Framework 4.5.2' do
          provider       Chef::Provider::Package::Windows
          source         "#{install_media_path}\\Redistr\\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
          installer_type :custom
          options        '/norestart /passive'
          action         :install
          returns        [0, 3010]
          notifies :reboot_now, 'reboot[DotNet Install Complete]', :immediately
        end
      end
    end
  end

  def install_sql_tools(downloaded_file_name)
    prerequisites_hash = Veeam::Helper.prerequisites_list(new_resource.version)

    prerequisites = {}
    prerequisites_hash.each do |item, prereq|
      prereq.map { |k, v| prerequisites[k] = v unless item == 'SQL' }
    end

    ruby_block 'Install the SQL Management Tools' do
      block do
        install_media_path = get_media_installer_location(downloaded_file_name)
        Chef::Log.debug 'Installing Veeam Backup Server Pre-Requisites... begin'
        prerequisites_root = "#{install_media_path}\\Redistr\\x64\\"

        prerequisites.each do |package_name, details|
          windows_package package_name do
            provider       Chef::Provider::Package::Windows
            source         "#{prerequisites_root}#{details}"
            installer_type :msi
            action         :install
          end
        end
        Chef::Log.debug 'Installing Veeam Backup Server Pre-Requisites... success'
      end
      action :run
    end
  end

  def install_sql_express(downloaded_file_name)
    installed_version_reg_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQL11.SQLEXPRESS\MSSQLServer\CurrentVersion'
    return 'Already Installed' if registry_key_exists?(installed_version_reg_key, :machine)
    config_file_path = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'ConfigurationFile.ini'))

    sql_sys_admin_list = 'NT AUTHORITY\SYSTEM'
    sql_sys_admin_list = node['veeam']['server']['vbr_service_user'] if node['veeam']['server']['vbr_service_user']

    template config_file_path do
      backup false
      sensitive true
      source ::File.join('sql_server', 'ConfigurationFile.ini.erb')
      provider Chef::Provider::File::Template
      variables(
        sqlSysAdminList: sql_sys_admin_list
      )
    end
    ruby_block 'Install the SQL Express' do
      block do
        install_media_path = get_media_installer_location(downloaded_file_name)
        windows_package 'Microsoft SQL Server 2014 (64-bit)' do
          source "#{install_media_path}\\Redistr\\x64\\SQLEXPR_x64_ENU.exe"
          timeout 1500
          installer_type :custom
          provider       Chef::Provider::Package::Windows
          options "/q /ConfigurationFile=#{config_file_path}"
          action :install
          returns [0, 42, 127, 3010]
        end
      end
    end
  end
end
