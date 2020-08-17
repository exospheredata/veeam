# Cookbook:: veeam
# Library:: helper
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.1.0
# Date:: 2017-02-07
#
# Copyright:: (c) 2020 Exosphere Data LLC, All Rights Reserved.
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

require 'chef/mixin/shell_out'
require 'chef/util/path_helper'

module Veeam
  module Helper
    def check_os_version(node)
      # '6.1.' is the numeric platform_version for Windows 2008R2.  If the node OS version is below that value, we must abort.
      raise ArgumentError, 'Veeam Backup and Replication management requires a Windows 2008R2 or higher host!' if node['platform_version'].to_f < '6.1'.to_f
      # If the kernel is not 64bit then raise an error, as we cannot proceed.
      raise ArgumentError, 'Veeam Backup and Replication requires an x86_64 host and cannot be installed on this machine' unless node['kernel']['machine'] =~ /x86_64/
    end

    def find_package_url(version)
      package_list(version)['package_url'] if package_list(version)
    end

    def find_package_checksum(version)
      package_list(version)['package_checksum'] if package_list(version)
    end

    def package_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        'package_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.0.0.902.iso',
        'package_checksum' => '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'
      }
      when '9.5' then {
        'package_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso',
        'package_checksum' => 'af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00'
      }
      when '9.5.0.711' then {
        'package_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso',
        'package_checksum' => 'af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00'
      }
      when '9.5.0.1038' then {
        'package_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.1038.Update2.iso',
        'package_checksum' => '180b142c1092c89001ba840fc97158cc9d3a37d6c7b25c93a311115b33454977'
      }
      when '9.5.0.1536' then {
        'package_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.1536.Update3.iso',
        'package_checksum' => '5020ef015e4d9ff7070d43cf477511a2b562d8044975552fd08f82bdcf556a43'
      }
      when '9.5.0.1922' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_9.5.0.1922.Update3a.iso',
        'package_checksum' => '9a6fa7d857396c058b2e65f20968de56f96bc293e0e8fd9f1a848c7d71534134'
      }
      when '9.5.4.2615' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_9.5.4.2615.Update4.iso',
        'package_checksum' => 'ecc27bbcf49104861566782701dca42375b324b4710e2fa79b5f8068c31c4494'
      }
      when '9.5.4.2866' then {
        'package_url' => 'https://download2.veeam.com/VeeamBackup&Replication_9.5.4.2866.Update4b_20191210.iso',
        'package_checksum' => 'cfc41596154563f60b74320634589721fd1110c87e04632068bc5234aada342e'
      }
      when '10.0' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_10.0.0.4461.iso',
        'package_checksum' => '26ddcc3df046af1ca1458b3040fc9024b4361ae1e51e1cf4516afe53fb024650'
      }
      when '10.0.0.4461' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_10.0.0.4461.iso',
        'package_checksum' => '26ddcc3df046af1ca1458b3040fc9024b4361ae1e51e1cf4516afe53fb024650'
      }
      when '10.0.1.4854' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_10.0.1.4854_20200723.iso',
        'package_checksum' => '378ae6a95ca683a12d9872eec7596bf2b17848c880812484e6e9e1dd55ec2dad'
      }
      end
    end

    def find_update_url(version)
      update_list(version)['update_url'] if update_list(version)
    end

    def find_update_checksum(version)
      update_list(version)['update_checksum'] if update_list(version)
    end

    def update_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.0.0.902.iso',
        'update_checksum' => '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'
      }
      when '9.5' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso',
        'update_checksum' => 'af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00'
      }
      when '9.5.0.711' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso',
        'update_checksum' => 'af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00'
      }
      when '9.5.0.823' then {
        'update_url' => 'https://download.veeam.com/VeeamBackup&Replication_9.5.0.823_Update1.zip',
        'update_checksum' => 'c07bdfb3b90cc609d21ba94584ba19d8eaba16faa31f74ad80814ec9288df492'
      }
      when '9.5.0.1038' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.1038.Update2.zip',
        'update_checksum' => 'd800bf5414f1bde95fba5fddbd86146c75a5a2414b967404792cc32841cb4ffb'
      }
      when '9.5.0.1536' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.1536.Update3.zip',
        'update_checksum' => '38ed6a30aa271989477684fdfe7b98895affc19df7e1272ee646bb50a059addc'
      }
      when '9.5.0.1922' then {
        'update_url' => 'http://download.veeam.com/VeeamBackup&Replication_9.5.0.1922.Update3a.zip',
        'update_checksum' => 'f6b3fc0963b09362c535ef49691c51d368266cc91d6833c80c70342161bb7123'
      }
      when '9.5.4.2615' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_9.5.4.2615.Update4.iso',
        'package_checksum' => 'ecc27bbcf49104861566782701dca42375b324b4710e2fa79b5f8068c31c4494'
      }
      when '9.5.4.2866' then {
        'update_url' => 'https://download.veeam.com/VeeamBackup&Replication_9.5.4.2866.Update4b_20191210.zip',
        'update_checksum' => 'e0b29d2585ba2adb0914976bf83d7f0e11c2db7365af9ff43a33cb36b23425c2'
      }
      when '10.0.0.4461' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_10.0.0.4461.iso',
        'package_checksum' => '26ddcc3df046af1ca1458b3040fc9024b4361ae1e51e1cf4516afe53fb024650'
      }
      when '10.0.1.4854' then {
        'package_url' => 'https://download.veeam.com/VeeamBackup&Replication_10.0.1.4854_20200723.iso',
        'package_checksum' => '378ae6a95ca683a12d9872eec7596bf2b17848c880812484e6e9e1dd55ec2dad'
      }
      end
    end

    def prerequisites_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2012 (x64)' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2012 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SqlExpress\SQLEXPR_x64_ENU.exe' }
      }
      when /9.0.0.\d+/ then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2012 (x64)' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2012 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SqlExpress\SQLEXPR_x64_ENU.exe' }
      }
      when '9.5' then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SqlExpress\SQLEXPR_x64_ENU.exe' }
      }
      when /9.5.0.\d+/ then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SqlExpress\SQLEXPR_x64_ENU.exe' }
      }
      when /9.5.4.\d+/ then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        '2' => { 'Microsoft Report Viewer 2015 Runtime' => '..\\ReportViewer.msi' },
        'SQL' => { 'Microsoft SQL Server 2016 (64-bit)' => 'SqlExpress\2016SP2\SQLEXPR_x64_ENU.exe' }
      }
      when '10.0' then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2016 (64-bit)' => 'SqlExpress\2016SP2\SQLEXPR_x64_ENU.exe' }
      }
      when /10.0.\d+/ then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2016 (64-bit)' => 'SqlExpress\2016SP2\SQLEXPR_x64_ENU.exe' }
      }
      end
    end

    def dotnet_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        # Microsoft .NET Framework 4.5.2
        '379893' => 'NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
      }
      when /9.\d+/ then {
        '379893' => 'NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
      }
      when '10.0' then {
        '461814' => 'NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
      }
      when /10.\d+/ then {
        '461814' => 'NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
      }
      end
    end

    def sqlexpress_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        'Microsoft SQL Server 2012 (64-bit)' => { 'installer' => 'SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL11.SQLEXPRESS' }
      }
      when /9.0.0.\d+/ then {
        'Microsoft SQL Server 2012 (64-bit)' => { 'installer' => 'SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL11.SQLEXPRESS' }
      }
      when '9.5' then {
        'Microsoft SQL Server 2012 (64-bit)' => { 'installer' => 'SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL11.SQLEXPRESS' }
      }
      when /9.5.0.\d+/ then {
        'Microsoft SQL Server 2012 (64-bit)' => { 'installer' => 'SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL11.SQLEXPRESS' }
      }
      when /9.5.4.\d+/ then {
        'Microsoft SQL Server 2016 (64-bit)' => { 'installer' => 'SqlExpress\2016SP1\SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL13.SQLEXPRESS' }
      }
      when '10.0' then {
        'Microsoft SQL Server 2016 (64-bit)' => { 'installer' => 'SqlExpress\2016SP2\SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL13.SQLEXPRESS' }
      }
      when /10.0.\d+/ then {
        'Microsoft SQL Server 2016 (64-bit)' => { 'installer' => 'SqlExpress\2016SP2\SQLEXPR_x64_ENU.exe', 'reg_key' => 'MSSQL13.SQLEXPRESS' }
      }
      end
    end

    def explorers_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an in
      when /9.\d+/ then {
        'ActiveDirectory' => { name: 'Veeam Explorer for Microsoft Active Directory' },
        'SQL' => { name: 'Veeam Explorer for Microsoft SQL Server' },
        'Exchange' => { name: 'Veeam Explorer for Microsoft Exchange' },
        'SharePoint' => { name: 'Veeam Explorer for Microsoft SharePoint' },
        'Oracle' => { name: 'Veeam Explorer for Oracle' }
      }
      when '10.0' then {
        'ActiveDirectory' => { name: 'Veeam Explorer for Microsoft Active Directory' },
        'SQL' => { name: 'Veeam Explorer for Microsoft SQL Server' },
        'Exchange' => { name: 'Veeam Explorer for Microsoft Exchange' },
        'SharePoint' => { name: 'Veeam Explorer for Microsoft SharePoint' },
        'Oracle' => { name: 'Veeam Explorer for Oracle' }
      }
      when /10.0.\d+/ then {
        'ActiveDirectory' => { name: 'Veeam Explorer for Microsoft Active Directory' },
        'SQL' => { name: 'Veeam Explorer for Microsoft SQL Server' },
        'Exchange' => { name: 'Veeam Explorer for Microsoft Exchange' },
        'SharePoint' => { name: 'Veeam Explorer for Microsoft SharePoint' },
        'Oracle' => { name: 'Veeam Explorer for Oracle' }
      }
      end
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

    def validate_powershell_out(script, timeout: nil, ignore_errors: false)
      # This seemed like the DRYest way to handle the output handling from PowerShell.
      cmd = powershell_out(script) if timeout.nil?
      cmd = powershell_out(script, timeout: timeout) unless timeout.nil?
      # Only return the output if there were no errors.
      return cmd.stdout.chomp if cmd.stderr == '' || cmd.stderr.nil? || ignore_errors
      raise cmd.inspect if cmd.stderr != ''
    end

    def find_current_veeam_solutions(package_name)
      cmd_str = <<-EOH
        $program = '#{package_name}'
        $x86 = (Get-ChildItem "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall" | gp )
        $x64 = (Get-ChildItem "HKLM:\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall" | gp )

        $x86version = ($x86 | ?{$_.DisplayName -eq $program})
        $x64version = ($x64 | ?{$_.DisplayName -eq $program})

        if($x86version) {
          return ($x86version.InstallLocation)
        } elseif($x64version) {
          return ($x64version.InstallLocation)
        } else {
          # Return nothing
        }
      EOH
      output = validate_powershell_out(cmd_str)
      raise ArgumentError, 'Unable to find the Veeam installation' unless output
      output
    end

    def find_current_veeam_version(package_name)
      veeam_package = find_current_veeam_solutions(package_name)
      veeam_exe = case package_name
                  when /Console/
                    "#{veeam_package}\\Console\\veeam.backup.shell.exe"
                  when /Server/
                    "#{veeam_package}\\Backup\\Packages\\VeeamDeploymentDll.dll"
                  when /Catalog/
                    "#{veeam_package}\\Backup Catalog\\VeeamDeploymentDll.dll"
                  else
                    raise "Unknown Package name: #{package_name}"
                  end
      cmd_str = <<-EOH
        $File = Get-Item -Path '#{veeam_exe}'
        $File.VersionInfo.ProductVersion
      EOH
      output = validate_powershell_out(cmd_str, ignore_errors: true)
      output = nil if output == ''
      output
    end

    def iso_installer(downloaded_file_name, new_resource)
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
        action :run
        not_if "[boolean] (Get-DiskImage -ImagePath '#{downloaded_file_name}').DevicePath"
      end
    end

    def extract_installer(downloaded_file_name, new_resource)
      package_name = downloaded_file_name.split('/').last
      package_type = ::File.extname(package_name)
      install_media_path = win_clean_path(::File.join(::Chef::Config[:file_cache_path], "Veeam/#{package_name.gsub(package_type, '')}"))
      update_path = win_clean_path(::File.join(install_media_path, '/Updates'))

      remote_file downloaded_file_name do
        source new_resource.package_url
        checksum new_resource.package_checksum
        use_conditional_get true # this should allow us to prevent duplicate downloads
        action :create
        not_if { ::File.exist?(update_path) }
      end

      archive_file win_clean_path(::File.join(install_media_path, '/Updates')) do
        destination win_clean_path(::File.join(install_media_path, '/Updates'))
        path downloaded_file_name
        action :extract
        not_if { ::File.exist?(update_path) }
      end

      install_media_path
    end

    def unmount_installer(downloaded_file_name)
      # Unmount the Veeam backup ISO.
      powershell_script 'Dismount Veeam media' do
        code <<-EOH
          Dismount-DiskImage -ImagePath "#{downloaded_file_name}"
        EOH
        action :run
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

    def win_clean_path(path)
      Chef::Util::PathHelper.cleanpath(path)
    end
  end
end
