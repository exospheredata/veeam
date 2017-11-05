# Cookbook Name:: veeam
# Resource:: catalog
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.2.0
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

default_action :install

property :package_name, String
property :share_path, String

property :package_url, String
property :package_checksum, String

property :install_dir, String
property :vm_catalogpath, String
property :vbrc_service_user, String
property :vbrc_service_password, String
property :vbrc_service_port, Integer

property :version, String, required: true
property :keep_media, [TrueClass, FalseClass], default: false

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)

action :install do
  veeam = Veeam::Helper # Library of helper methods
  veeam.check_os_version(node)

  # We will use the Windows Helper 'is_package_installed?' to see if the Catalog Server is installed.  If it is installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  return false if is_package_installed?('Veeam Backup Catalog')

  # We need to verify that .NET Framework 4.5.2 or higher has been installed on the machine
  raise 'The Veeam Backup and Recovery Server requires that Microsoft .NET Framework 4.5.2 or higher be installed.  Please install the Veeam pre-requisites' if find_current_dotnet < 379893

  raise ArgumentError, 'The VBRC service password must be set if a username is supplied' if new_resource.vbrc_service_user && new_resource.vbrc_service_password.nil?

  package_save_dir = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'package'))

  # This will only create the directory if it does not exist which is likely the case if we have
  # never performed a remote_file install.
  directory package_save_dir do
    action :create
  end

  # Call the Veeam::Helper to find the correct URL based on the version of the Veeam Backup and Recovery edition passed
  # as an attribute.
  unless new_resource.package_url
    new_resource.package_url = veeam.find_package_url(new_resource.version)
    new_resource.package_checksum = veeam.find_package_checksum(new_resource.version)
    Chef::Log.info(new_resource.package_url)
  end

  # Halt this process now.  There is no URL for the package.
  raise ArgumentError, 'You must provide a package URL or choose a valid version' unless new_resource.package_url

  # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
  # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
  # This is easy to handle as long as we add a method to check for the file base type.

  Chef::Log.debug('Downloading Veeam Backup and Recovery software via URL')
  package_name = new_resource.package_url.split('/').last
  installer_file_name = win_friendly_path(::File.join(package_save_dir, package_name))
  download_installer(installer_file_name)

  ruby_block 'Install the Backup Catalog application' do
    block do
      Chef::Log.debug 'Installing Veeam Backup and Recovery catalog'
      install_media_path = get_media_installer_location(installer_file_name)
      perform_catalog_install(install_media_path)
    end
    action :run
  end

  # Dismount the ISO if it is mounted
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
      if ( [string]::IsNullOrEmpty($DriveLetter) ){ throw 'The ISO did not mount and we have no idea where why.' }
      return ( $DriveLetter +':\' )
    EOH
    output = validate_powershell_out(cmd_str)
    raise ArgumentError, 'Unable to find the Veeam installation media' unless output
    Chef::Log.debug "Found the Veeam installation media at Drive Letter [#{output}]"
    output
  end

  def perform_catalog_install(install_media_path)
    Chef::Log.debug 'Installing Veeam Backup Catalog service... begin'
    # In this case, we have many possible combinations of extra arugments that would need to be passed to the installer.
    # The process will create a usable string formatted to support those optional arguments. It seemed safer to attempt
    # to do all of this work inside of Ruby rather than the back and forth with PowerShell scripts. Note that each of these
    # resources are considered optional and will only be set if sent to use by the resource block.
    xtra_arguments = ''
    xtra_arguments.concat(" INSTALLDIR=\"#{new_resource.install_dir} \" ") unless new_resource.install_dir.nil?
    xtra_arguments.concat(" VM_CATALOGPATH=\"#{new_resource.vm_catalogpath} \" ") unless new_resource.vm_catalogpath.nil?
    xtra_arguments.concat(" VBRC_SERVICE_USER=\"#{new_resource.vbrc_service_user}\" ") unless new_resource.vbrc_service_user.nil?
    xtra_arguments.concat(" VBRC_SERVICE_PASSWORD=\"#{new_resource.vbrc_service_password}\" ") unless new_resource.vbrc_service_password.nil?
    xtra_arguments.concat(" VBRC_SERVICE_PORT=\"#{new_resource.vbrc_service_port}\" ") unless new_resource.vbrc_service_port.nil?

    cmd_str = <<-EOH
      $veeam_backup_catalog_installer = ( "#{install_media_path}\\Catalog\\VeeamBackupCatalog64.msi")
      Write-Host (' /qn /i ' + $veeam_backup_catalog_installer + ' #{xtra_arguments}')
      $output = (Start-Process -FilePath "msiexec.exe" -ArgumentList $(' /qn /i ' + $veeam_backup_catalog_installer + ' #{xtra_arguments}') -Wait -Passthru -ErrorAction Stop)
      if ( $output.ExitCode -ne 0){
        throw ("The install failed with ExitCode [{0}].  The package is {1}" -f $output.ExitCode, $veeam_backup_catalog_installer )
      }
    EOH
    validate_powershell_out(cmd_str)
    Chef::Log.debug 'Installing Veeam Backup Catalog service... success'
  end
end
