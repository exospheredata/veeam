# Cookbook Name:: veeam
# Provider:: catalog
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.1.0
# Date:: 2017-02-07
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

# Support "no-operation" mode
def whyrun_supported?
  true
end

use_inline_resources

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)

action :install do
  check_os_version

  # TODO:  We should add a registry check here to see if the application has already been installed. This will help prevent
  # multiple unnecessary downloads.
  installed_version_reg_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Veeam\Veeam Backup Catalog'
  return new_resource.updated_by_last_action(true) if registry_key_exists?(installed_version_reg_key, :machine)

  # Start by determining if this is a download or we need to mount the media via CIFS
  if new_resource.package_url
    # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
    # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
    # This is easy to handle as long as we add a method to check for the file base type.

    Chef::Log.debug('Downloading Veeam Backup and Recovery software via URL')
    package_save_dir = win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package'))
    package_name = new_resource.package_url.split('/').last
    downloaded_file_name = win_friendly_path(::File.join(package_save_dir, package_name))
    # veeam_installer = win_friendly_path(::File.join(downloaded_file_name.gsub('.iso', ''), 'SETUP.EXE'))
    installer_location = downloaded_file_name.gsub('.iso', '')

    # This will only create the directory if it does not exist which is likely the case if we have
    # never performed a remote_file install.
    directory package_save_dir do
      action :create
    end

    # We will want to remove the tmp downloaded file later to save space
    file downloaded_file_name do
      action :nothing
    end

    # We will want to remove the tmp directory later to save space
    directory installer_location do
      action :nothing
      recursive true
    end

    # Download the Installer media
    remote_file downloaded_file_name do
      source new_resource.package_url
      checksum new_resource.package_checksum
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

    ruby_block 'Install the Backup Catalog application' do
      block do
        Chef::Log.debug 'Installing Veeam Backup and Recovery catalog'
        cmd_str = <<-EOH
          $DriveLetter = (Get-DiskImage -ImagePath '#{downloaded_file_name}' | Get-Volume).DriveLetter;
          if ( [string]::IsNullOrEmpty($DriveLetter) ){ throw 'The ISO did not mount and we have no idea where why.' }
          $veeam_backup_catalog_installer = ( "{0}:\\Catalog\\VeeamBackupCatalog64.msi" -f $DriveLetter)
          $output = (Start-Process -FilePath "msiexec.exe" -ArgumentList " /qn /i $veeam_backup_catalog_installer" -Wait -Passthru -ErrorAction Stop)
          if ( $output.ExitCode -ne 0){
            throw ("The install failed with ExitCode [{0}].  The package is {1}" -f $output.ExitCode, $veeam_backup_catalog_installer )
          }
        EOH
        cmd = powershell_out(cmd_str)
        # Check powershell output
        raise cmd.stderr if cmd.stderr != ''
      end
      action :run
    end

    new_resource.updated_by_last_action(true)
  else
    # TODO: Probably should add an option to handle Files from a CIFS Share
    Chef::Log.debug('No package URL was shared')
    raise ArgumentError, 'You must provide a package URL'
  end
end

def check_os_version
  return if node['platform_version'].to_f >= '6.1'.to_f # '6.1.' is the numeric platform_version for Windows 2008R2
  raise ArgumentError, 'Veeam Backup and recovery management requires a Windows 2008R2 or higher host!'
end
