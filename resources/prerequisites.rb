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
::Chef::Provider.send(:include, Veeam::Helper)

action :install do
  check_os_version(node)

  # Call the Veeam::Helper to find the correct URL based on the version of the Veeam Backup and Recovery edition passed
  # as an attribute.
  unless new_resource.package_url
    new_resource.package_url = find_package_url(new_resource.version)
    new_resource.package_checksum = find_package_checksum(new_resource.version)
  end

  # Halt this process now.  There is no URL for the package.
  raise ArgumentError, 'You must provide a package URL or choose a valid version' unless new_resource.package_url

  # Determine if all of the Veeam pre-requisites are installed and if so, then skip the processing.
  prerequisites_required  = []
  installed_prerequisites = []
  prerequisites_hash      = prerequisites_list(new_resource.version)

  prerequisites_hash.each do |item, prerequisites|
    package_name = prerequisites.map { |k, _v| k }.join(',')
    unless item == 'SQL' && new_resource.install_sql == false
      prerequisites_required.push(package_name)
      installed_prerequisites.push(package_name) if is_package_installed?(package_name)
    end
  end

  # Compare the required Prerequisites with those installed.  If all are installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  return false if (prerequisites_required - installed_prerequisites).empty? && find_current_dotnet >= 379893

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
  iso_installer(installer_file_name, new_resource)

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
    prerequisites_hash = prerequisites_list(new_resource.version)

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
    output_file      = win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'sql_install.log'))
    sql_build_script = win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'sql_build_script.ps1'))

    sql_sys_admin_list = "NT AUTHORITY\\SYSTEM\" \"#{node['hostname']}\\#{ENV['USERNAME']}"
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
        sql_installer      = "#{install_media_path}\\Redistr\\x64\\SQLEXPR_x64_ENU.exe"

        template sql_build_script do
          backup false
          sensitive true
          source ::File.join('sql_server', 'sql_build_script.ps1.erb')
          variables(
            sql_build_command: "#{sql_installer} /q /ConfigurationFile=#{config_file_path}",
            outputFilePath: output_file
          )
          action :create
        end

        setup_task(sql_build_script)
      end
    end

    ruby_block 'Check SQL Install State' do
      block do
        monitor_task_status('Setup SQL Install Task')
        Chef::Log.debug 'Check the status of the install'
        cmd_str = <<-EOH
          $results = ( Get-Content -Path #{output_file} | Out-String | ConvertFrom-Json );
          if (-not [string]::IsNullOrEmpty($results.error) ){ throw $results.error }
        EOH
        cmd = powershell_out(cmd_str)
        # Check powershell output
        raise cmd.stderr if cmd.stderr != ''
      end
      action :run
    end

    [config_file_path, sql_build_script].each do |filename|
      file filename do
        action :delete
        backup false
      end
    end

    windows_task 'Remove SQL Install Task' do
      task_name 'Setup SQL Install Task'
      action :delete
    end
  end

  def setup_task(sql_build_script)
    windows_task 'Setup SQL Install Task' do
      command "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -File #{sql_build_script}"
      run_level :highest
      frequency :onstart
      action :create
    end

    powershell_script 'Modify Task to allow execution on laptop' do
      code <<-EOH
        $TaskName = 'Setup SQL Install Task'
        $Task = Get-ScheduledTask -TaskName $TaskName
        if($Task){
          $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Compatibility 'Win8'
          Set-ScheduledTask -TaskName $TaskName -Settings $Settings
        }
      EOH
      action :run
      notifies :run, 'windows_task[Setup SQL Install Task]', :immediately
    end
  end

  def monitor_task_status(task_name)
    Chef::Log.info "#{task_name}: Monitoring Task until completion"
    cmd_str = <<-EOH
      $TaskName = "#{task_name}";
        $Task = Get-ScheduledTask -TaskName $TaskName
        while($Task.State -eq "Running")
        {
            Start-Sleep -s 5
            $Task = Get-ScheduledTask -TaskName $TaskName
        }
        if($Task.State -eq "Ready"){
            $TaskResults = ($Task | Get-ScheduledTaskInfo)
            if($TaskResults.LastTaskResult -ne 0){
                throw $($TaskName + ": failed to execute.  Error code {0}" -f $TaskResults.LastTaskResult)
            } else {
          return # Success
        }
        } else {
            throw $($Task | Get-ScheduledTaskInfo).LastTaskResult
        }
        EOH
    # We need to extend this time in the event there is a long running task that we have to wait to complete.
    # The default is 600 but we will bump to 3600
    #
    # TODO: make the timeout on tasks variable
    cmd = powershell_out(cmd_str, timeout: 5400)
    # Check powershell output
    raise cmd.stderr unless cmd.stderr.nil? || cmd.stderr.empty?
    Chef::Log.debug "#{task_name}: Monitoring Task completed"
  end
end
