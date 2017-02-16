# Cookbook Name:: veeam
# Provider:: server
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
  installed_version_reg_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Veeam\Veeam Backup server'
  return new_resource.updated_by_last_action(false) if registry_key_exists?(installed_version_reg_key, :machine)

  raise ArgumentError, 'The Veeam Backup and Recovery EULA must be accepted.  Please set the node attribute [\'veeam\'][\'server\'][\'accept_eula\'] to \'true\' ' if new_resource.accept_eula.nil?
  raise ArgumentError, 'The VBR service password must be set if a username is supplied' if new_resource.vbr_service_user && new_resource.vbr_service_password.nil?

  package_save_dir = win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package'))

  # This will only create the directory if it does not exist which is likely the case if we have
  # never performed a remote_file install.
  directory package_save_dir do
    action :create
  end

  # Start by determining if this is a download or we need to mount the media via CIFS
  if new_resource.package_url
    # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
    # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
    # This is easy to handle as long as we add a method to check for the file base type.

    Chef::Log.debug('Downloading Veeam Backup and Recovery software via URL')
    package_name = new_resource.package_url.split('/').last
    downloaded_file_name = win_friendly_path(::File.join(package_save_dir, package_name))

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

    ruby_block 'Install the Backup server application' do
      block do
        Chef::Log.debug 'Installing Veeam Backup and Recovery server'
        install_media_path = get_media_installer_location(downloaded_file_name)
        perform_server_install(install_media_path)
      end
      action :run
    end

    # Unmount the Veeam backup ISO.
    powershell_script 'Dismount Veeam media' do
      code <<-EOH
        Dismount-DiskImage -ImagePath "#{downloaded_file_name}"
      EOH
      guard_interpreter :powershell_script
      only_if "[boolean] (Get-DiskImage -ImagePath '#{downloaded_file_name}').DevicePath"
    end

    return new_resource.updated_by_last_action(true) if new_resource.keep_media

    # Since the property 'keep_media' was set to false, we will need to remove it

    # We will want to remove the tmp downloaded file later to save space
    file downloaded_file_name do
      backup false
      action :delete
    end

    new_resource.updated_by_last_action(true)
  else
    # TODO: Probably should add an option to handle Files from a CIFS Share.  As of this writing, we will only
    # support downloaded ISO files
    Chef::Log.debug('No package URL was shared')
    raise ArgumentError, 'You must provide a package URL'
  end
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

def get_media_installer_location(downloaded_file_name)
  # When downloading and mounting the ISO, we need to track back to the Drive Letter.  This method will handle
  # the look-up and keep the logic out of the main installation code.
  Chef::Log.debug 'Searching for the Veeam installation media Drive Letter...'
  cmd_str = <<-EOH
    $DriveLetter = (Get-DiskImage -ImagePath '#{downloaded_file_name}' | Get-Volume).DriveLetter;
    if ( [string]::IsNullOrEmpty($DriveLetter) ){ throw 'The ISO did not mount and we have no idea where why.' }
    return ( $DriveLetter +':\' )
  EOH
  output = validate_powershell_out(cmd_str)
  raise ArgumentError, 'Unable to find the Veeam installation media' unless output
  Chef::Log.debug "Found the Veeam installation media at Drive Letter [#{output}]"
  output
end

def perform_server_install(install_media_path)
  Chef::Log.debug 'Installing Veeam Backup server service... begin'
  # In this case, we have many possible combinations of extra arugments that would need to be passed to the installer.
  # The process will create a usable string formatted to support those optional arguments. It seemed safer to attempt
  # to do all of this work inside of Ruby rather than the back and forth with PowerShell scripts. Note that each of these
  # resources are considered optional and will only be set if sent to use by the resource block.
  xtra_arguments = ''
  xtra_arguments.concat(" ACCEPTEULA=\"#{new_resource.accept_eula ? 'YES' : 'NO'}\" ") unless new_resource.accept_eula.nil?
  xtra_arguments.concat(" INSTALLDIR=\"#{new_resource.install_dir} \" ") unless new_resource.install_dir.nil?
  xtra_arguments.concat(" VBR_LICENSE_FILE=\"#{new_resource.vbr_license_file} \" ") unless new_resource.vbr_license_file.nil?
  xtra_arguments.concat(" VBR_CHECK_UPDATES=\"#{new_resource.vbr_check_updates ? 1 : 0} \" ") unless new_resource.vbr_check_updates.nil?
  # VBR Service Configuration
  xtra_arguments.concat(" VBR_SERVICE_USER=\"#{new_resource.vbr_service_user}\" ") unless new_resource.vbr_service_user.nil?
  xtra_arguments.concat(" VBR_SERVICE_PASSWORD=\"#{new_resource.vbr_service_password}\" ") unless new_resource.vbr_service_password.nil?
  xtra_arguments.concat(" VBR_SERVICE_PORT=\"#{new_resource.vbr_service_port}\" ") unless new_resource.vbr_service_port.nil?
  xtra_arguments.concat(" VBR_SECURE_CONNECTIONS_PORT=\"#{new_resource.vbr_secure_connections_port}\" ") unless new_resource.vbr_secure_connections_port.nil?
  xtra_arguments.concat(" VBR_SERVICE_PORT=\"#{new_resource.vbr_service_port}\" ") unless new_resource.vbr_service_port.nil?
  # SQL Server Connection Details
  xtra_arguments.concat(" VBR_SQLSERVER_SERVER=\"#{new_resource.vbr_sqlserver_server}\" ") unless new_resource.vbr_sqlserver_server.nil?
  xtra_arguments.concat(" VBR_SQLSERVER_DATABASE=\"#{new_resource.vbr_sqlserver_database}\" ") unless new_resource.vbr_sqlserver_database.nil?
  xtra_arguments.concat(" VBR_SQLSERVER_AUTHENTICATION=\"#{new_resource.vbr_sqlserver_auth}\" ") unless new_resource.vbr_sqlserver_auth.nil?
  xtra_arguments.concat(" VBR_SQLSERVER_USERNAME=\"#{new_resource.vbr_sqlserver_username}\" ") unless new_resource.vbr_sqlserver_username.nil?
  xtra_arguments.concat(" VBR_SQLSERVER_PASSWORD=\"#{new_resource.vbr_sqlserver_password}\" ") unless new_resource.vbr_sqlserver_password.nil?
  xtra_arguments.concat(" PF_AD_NFSDATASTORE=\"#{new_resource.pf_ad_nfsdatastore}\" ") unless new_resource.pf_ad_nfsdatastore.nil?

  cmd_str = <<-EOH
    $veeam_backup_server_installer = ( "#{install_media_path}\\Backup\\Server.x64.msi")
    Write-Host (' /qn /i ' + $veeam_backup_server_installer + ' #{xtra_arguments}')
    $output = (Start-Process -FilePath "msiexec.exe" -ArgumentList $(' /qn /i ' + $veeam_backup_server_installer + ' #{xtra_arguments}') -Wait -Passthru -ErrorAction Stop)
    if ( $output.ExitCode -ne 0){
      throw ("The install failed with ExitCode [{0}].  The package is {1}" -f $output.ExitCode, $veeam_backup_server_installer )
    }
  EOH
  validate_powershell_out(cmd_str)
  Chef::Log.debug 'Installing Veeam Backup server service... success'
end
