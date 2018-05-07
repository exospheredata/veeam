# Cookbook Name:: veeam
# Resource:: proxy
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

default_action :add

property :hostname, String, name_property: true, required: true

# VBR Server Connection Properties
property :vbr_server, String, required: true
property :vbr_server_port, [Integer, String], default: 9392
property :vbr_username, String, sensitive: true, required: true
property :vbr_password, String, sensitive: true, required: true

# Proxy Server Credentials
property :proxy_username, String, sensitive: true
property :proxy_password, String, sensitive: true

property :proxy_type, String, equal_to: %w(vmware hyperv), default: 'vmware'

property :description, [String, nil]

# => Specifies the number of concurrent tasks that can be assigned to the proxy simultaneously.
# => Permitted values: 1-100.
property :max_tasks, Integer, regex: [/(?:\b|-)([1-9]{1,2}[0]?|100)\b/], default: 2

# => Specifies the transport mode used by the backup proxy
property :transport_mode, String, equal_to: %w(Auto DirectStorageAccess HotAdd Nbd), default: 'Auto'

#   *** Future Properties ***
# => Specifies the mode the proxy will use to connect to datastores
property :datastore_mode, String, equal_to: %w(Auto Manual), default: 'Auto'

# => Specifies the list of datastores to which the backup proxy has a direct SAN or NFS connection.
property :datastore, String

# => Indicates if the backup proxy must fail over to the Network transport mode if it fails
# => to transport data in the Direct storage access or Virtual appliance transport mode.
property :enable_failover_to_ndb, [TrueClass, FalseClass], default: false

# => Indicates if VM data must be transported over an encrypted SSL connection in the Network transport mode.
property :host_encryption, [TrueClass, FalseClass], default: false
#   *************************

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)
::Chef::Provider.send(:include, Veeam::Helper)

action :add do
  check_os_version(node)
  # We will use the Windows Helper 'is_package_installed?' to see if the Console is installed.  If it is installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  no_console_error = 'This resource requires that the Veeam Backup & Replication Console be installed on this host'
  raise ArgumentError, no_console_error unless is_package_installed?('Veeam Backup & Replication Console')

  return false if proxy_currently_registered && server_currently_registered

  raise ArgumentError, 'The Proxy Username is a required attribute' if new_resource.proxy_username.nil?
  raise ArgumentError, 'The Proxy Password is a required attribute' if new_resource.proxy_password.nil?

  powershell_script 'Register Windows Server' do
    code <<-EOH
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        $VbrCredentials = (Get-VBRCredentials -Name #{new_resource.proxy_username})
        if ($VbrCredentials -is [array]){
          $VbrCredentials = $VbrCredentials[0]
        }
        if (!$VbrCredentials){
          $VbrCredentials = (Add-VBRCredentials `
            -User #{new_resource.proxy_username} `
            -Password #{new_resource.proxy_password} `
            -Description "ADDED BY CHEF: Proxy Server Credentials" `
            -Type Windows)
        }

        $VbrServer = Get-VBRServer -Name #{new_resource.hostname}
        if(!$VbrServer) {
          Add-VBRWinServer -Name #{new_resource.hostname} `
            -Description "#{new_resource.description ? "ADDED by CHEF: #{new_resource.description}" : 'ADDED by CHEF: Proxy Server'}" `
            -Credentials $VbrCredentials
        }
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    action :run
    not_if { server_currently_registered }
  end

  powershell_script 'Register Veeam Proxy' do
    code <<-EOH
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        $VbrCredentials = (Get-VBRCredentials -Name #{new_resource.proxy_username})
        if (!$VbrCredentials){
          throw "No stored Credentials found for User: #{new_resource.proxy_username}"
        }
        if ($VbrCredentials -is [array]){
          $VbrCredentials = $VbrCredentials[0]
        }

        if("#{new_resource.proxy_type}" -eq "vmware"){
          $VbrViProxy = Get-VBRViProxy -Name #{new_resource.hostname}
          if(!$VbrViProxy) {
            Add-VBRViProxy -Server #{new_resource.hostname} `
              -Description "#{new_resource.description ? "ADDED by CHEF: #{new_resource.description}" : 'ADDED by CHEF: Proxy Server'}" `
              -MaxTasks #{new_resource.max_tasks} `
              -TransportMode #{new_resource.transport_mode}
          }
        }
        elseif ("#{new_resource.proxy_type}" -eq "hyperv"){
          $VbrHvProxy = Get-VBRHvProxy -Name #{new_resource.hostname}
          if(!$VbrHvProxy) {
            Add-VBRHvProxy -Server #{new_resource.hostname} `
              -Description "#{new_resource.description ? "ADDED by CHEF: #{new_resource.description}" : 'ADDED by CHEF: Proxy Server'}" `
              -MaxTasks #{new_resource.max_tasks} `
          }
        }
        else {
          throw "Invalid Proxy Type provided: #{new_resource.proxy_type}"
        }
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    action :run
    not_if { proxy_currently_registered }
  end
end

action :remove do
  check_os_version(node)
  # We will use the Windows Helper 'is_package_installed?' to see if the Console is installed.  If it is installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  no_console_error = 'This resource requires that the Veeam Backup & Replication Console be installed on this host'
  raise ArgumentError, no_console_error unless is_package_installed?('Veeam Backup & Replication Console')

  return false if !proxy_currently_registered && !server_currently_registered

  powershell_script 'Remove Veeam Proxy' do
    code <<-EOH
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        if("#{new_resource.proxy_type}" -eq "vmware"){
          $VbrViProxy = Get-VBRViProxy -Name #{new_resource.hostname}
          if($VbrViProxy) {
            Remove-VBRViProxy -Proxy #{new_resource.hostname} -Confirm:$False
          }
        }
        elseif ("#{new_resource.proxy_type}" -eq "hyperv"){
          $VbrHvProxy = Get-VBRHvProxy -Name #{new_resource.hostname}
          if($VbrHvProxy) {
            Remove-VBRHvProxy -Proxy #{new_resource.hostname} -Confirm:$False
          }
        }
        else {
          throw "Invalid Proxy Type provided: #{new_resource.proxy_type}"
        }
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    action :run
    only_if { proxy_currently_registered }
  end

  powershell_script 'Remove Windows Server' do
    code <<-EOH
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        $VbrServer = Get-VBRServer -Name #{new_resource.hostname}
        if($VbrServer) {
          Remove-VBRServer -Server #{new_resource.hostname} -Confirm:$False
        }
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    action :run
    only_if { server_currently_registered }
  end
end

action_class do
  def whyrun_supported?
    true
  end

  def server_currently_registered
    cmd_str = <<-EOH
      # Check if Host is registered
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop
        $VbrServer = Get-VBRServer -Name "#{new_resource.name}" -ErrorAction SilentlyContinue
        if($VbrServer){
          return $True
        }
        return $False
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    output = validate_powershell_out(cmd_str)
    return false if output == 'False'
    true
  end

  def proxy_currently_registered
    cmd_str = <<-EOH
      # Check if Proxy is registered
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        if("#{new_resource.proxy_type}" -eq "vmware"){
          $VbrViProxy = Get-VBRViProxy -Name "#{new_resource.name}" -ErrorAction SilentlyContinue
          if($VbrViProxy){
            return $True
          }
        }
        elseif ("#{new_resource.proxy_type}" -eq "hyperv"){
          $VbrHvProxy = Get-VBRHvProxy -Name #{new_resource.hostname} -ErrorAction SilentlyContinue
          if(!$VbrHvProxy) {
            return $True
          }
        }
        else {
          throw "Invalid Proxy Type provided: #{new_resource.proxy_type}"
        }
        return $False
      } catch {
        throw $_.Exception.message
      } finally {
        Disconnect-VBRServer
      }
    EOH
    output = validate_powershell_out(cmd_str)
    return false if output == 'False'
    true
  end
end
