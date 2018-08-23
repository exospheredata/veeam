# Cookbook Name:: veeam
# Resource:: host
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 1.0.0
# Date:: 2018-08-23
#
# Copyright (c) 2018 Exosphere Data LLC, All Rights Reserved.
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

# Host Server Credentials
property :host_username, String, sensitive: true
property :host_password, String, sensitive: true

property :host_type, String, equal_to: %w(vmware esxi esx_legacy hyperv hyperv_cluster hyperv_scvmm smbv3_host smbv3_cluster windows linux), required: true

property :host_port, [Integer, String], default: 443

property :description, [String, nil]

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)
::Chef::Provider.send(:include, Veeam::Helper)

action :add do
  check_os_version(node)
  # We will use the Windows Helper 'is_package_installed?' to see if the Console is installed.  If it is installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  no_console_error = 'This resource requires that the Veeam Backup & Replication Console be installed on this host'
  raise ArgumentError, no_console_error unless is_package_installed?('Veeam Backup & Replication Console')

  return false if server_currently_registered

  raise ArgumentError, 'The Host Username is a required attribute' if new_resource.host_username.nil?
  raise ArgumentError, 'The Host Password is a required attribute' if new_resource.host_password.nil?

  powershell_script 'Register Host Server' do
    code <<-EOH
      Add-PSSnapin VeeamPSSnapin
      try {
        Connect-VBRServer `
          -Server #{new_resource.vbr_server} `
          -User #{new_resource.vbr_username} `
          -Password #{new_resource.vbr_password} `
          -Port #{new_resource.vbr_server_port} `
          -ErrorAction Stop

        $VbrCredentials = (Get-VBRCredentials -Name #{new_resource.host_username})
        if ($VbrCredentials -is [array]){
          $VbrCredentials = $VbrCredentials[0]
        }
        if (!$VbrCredentials){
          $VbrCredentials = (Add-VBRCredentials `
            -User #{new_resource.host_username} `
            -Password #{new_resource.host_password} `
            -Description "ADDED BY CHEF: #{new_resource.host_type.upcase} Server Credentials" `
            -Type Windows)
        }

        $VbrServer = Get-VBRServer -Name #{new_resource.hostname}
        if(!$VbrServer) {
          $arguments  = " -Name #{new_resource.hostname}"
          $arguments += " -Port #{new_resource.host_port}"
          $arguments += " -Description '#{new_resource.description ? "ADDED by CHEF: #{new_resource.description}" : "ADDED by CHEF: #{new_resource.host_type.upcase} Server"}'"
          $arguments += " -Credentials $VbrCredentials"

          switch("#{new_resource.host_type}"){
            "vmware" {
              $command = "Add-VBRvCenter"
            }
            "esxi" {
              $command = "Add-VBRESXi"
            }
            "esx_legacy" {
              $command = "Add-VBRESX"
            }
            "hyperv" {
              $command = "Add-VBRHvHost"
            }
            "hyperv_cluster" {
              $command = "Add-VBRHvCluster"
            }
            "hyperv_scvmm" {
              $command = "Add-VBRHvScvmm"
            }
            "smbv3_host" {
              $command = "Add-VBRSmbV3Host"
            }
            "smbv3_cluster" {
              $command = "Add-VBRSmbV3Cluster"
            }
            "windows" {
              $command = "Add-VBRWinServer"
            }
            "linux" {
              $command = "Add-VBRLinux"
            }
            default {
              throw "Unknown Host Type: #{new_resource.host_type}.  Unable to add host to Veeam Backup and Replication Server."
            }
          }

          Invoke-Expression -Command $($command + $arguments)
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
end

action :remove do
  check_os_version(node)
  # We will use the Windows Helper 'is_package_installed?' to see if the Console is installed.  If it is installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  no_console_error = 'This resource requires that the Veeam Backup & Replication Console be installed on this host'
  raise ArgumentError, no_console_error unless is_package_installed?('Veeam Backup & Replication Console')

  return false unless server_currently_registered

  powershell_script 'Remove Host Server' do
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
end
