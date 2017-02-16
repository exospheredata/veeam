# Cookbook Name:: veeam
# Provider:: prerequisites
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

  package_save_dir = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'package'))

  # This will only create the directory if it does not exist which is likely the case if we have
  # never performed a remote_file install.
  directory package_save_dir do
    action :create
  end

  # Start by determining if this is a download or we need to mount the media via CIFS
  raise ArgumentError, 'You must provide a package URL' unless new_resource.package_url

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

  new_resource.updated_by_last_action(true)
end

def validate_powershell_out(script)
  # This seemed like the DRYest way to handle the output handling from PowerShell.
  cmd = powershell_out(script)
  # Check powershell output
  raise cmd.inspect if cmd.stderr != ''
  cmd.stdout.chop
end

def check_os_version
  # Return True otherwise raise an exeption.  This is the cleanest way to handle minimum versions.  We might add
  # a secondary check for highest version at some point.
  return if node['platform_version'].to_f >= '6.1'.to_f # '6.1.' is the numeric platform_version for Windows 2008R2
  raise ArgumentError, 'Veeam Backup and recovery management requires a Windows 2008R2 or higher host!'
end

def download_installer(downloaded_file_name)
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
  installed_version_reg_key = registry_get_values('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full')
  current_dotnet_version = installed_version_reg_key.nil? ? 0 : installed_version_reg_key[6][:data]

  return 'Already installed' if current_dotnet_version >= 379893
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
        checksum       '6c2c589132e830a185c5f40f82042bee3022e721a216680bd9b3995ba86f3781'
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
  prerequisites = {
    'Microsoft SQL Server System CLR Types (x64)' => {
      'installer' => 'SQLSysClrTypes.msi',
      'checksum' => '674c396e9c9bf389dd21cec0780b3b4c808ff50c570fa927b07fa620db7d4537'
    },
    'Microsoft SQL Server 2012 Management Objects (x64)' => {
      'installer' => 'SharedManagementObjects.msi',
      'checksum' => 'ed753d85b51e7eae381085cad3dcc0f29c0b72f014f8f8fba1ad4e0fe387ce0a'
    }
  }
  ruby_block 'Install the SQL Management Tools' do
    block do
      install_media_path = get_media_installer_location(downloaded_file_name)
      Chef::Log.debug 'Installing Veeam Backup Server Pre-Requisites... begin'
      prerequisites_root = "#{install_media_path}\\Redistr\\x64\\"

      prerequisites.each do |package_name, details|
        windows_package package_name do
          provider       Chef::Provider::Package::Windows
          source         "#{prerequisites_root}#{details['installer']}"
          checksum       details['checksum']
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
  return 'Skip Sql Install' unless node['veeam']['server']['vbr_sqlserver_server'].nil?
  installed_version_reg_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQL11.SQLEXPRESS\MSSQLServer\CurrentVersion'
  return 'Already Installed' if registry_key_exists?(installed_version_reg_key, :machine)
  config_file_path = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'ConfigurationFile.ini'))

  sql_sys_admin_list = 'NT AUTHORITY\SYSTEM'
  sql_sys_admin_list = node['veeam']['server']['vbr_sqlserver_username'] if node['veeam']['server']['vbr_sqlserver_username']

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
        checksum '7fae66c782d2fa3428530a074d091b51dcd17dee52b5a031c58505b01027d10f'
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
