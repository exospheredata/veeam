# Cookbook Name:: veeam
# Library:: helper
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

require 'chef/mixin/shell_out'

module Veeam
  class Helper
    extend Chef::Mixin::ShellOut

    def self.check_os_version(node)
      # '6.1.' is the numeric platform_version for Windows 2008R2.  If the node OS version is below that value, we must abort.
      raise ArgumentError, 'Veeam Backup and Replication management requires a Windows 2008R2 or higher host!' if node['platform_version'].to_f < '6.1'.to_f
      # If the kernel is not 64bit then raise an error, as we cannot proceed.
      raise ArgumentError, 'Veeam Backup and Replication requires an x86_64 host and cannot be installed on this machine' unless node['kernel']['machine'] =~ /x86_64/
    end

    def self.find_package_url(version)
      package_list(version)['package_url'] if package_list(version)
    end

    def self.find_package_checksum(version)
      package_list(version)['package_checksum'] if package_list(version)
    end

    def self.package_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        'package_url' => 'http://download2.veeam.com/VeeamBackup&Replication_9.0.0.902.iso',
        'package_checksum' => '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'
      }
      when '9.5' then {
        'package_url' => 'http://download2.veeam.com/VeeamBackup&Replication_9.5.0.711.iso',
        'package_checksum' => 'af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00'
      }
      end
    end

    def self.prerequisites_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2012 (x64)' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2012 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SQLEXPR_x64_ENU.exe' }
      }
      when '9.5' then {
        '0' => { 'Microsoft System CLR Types for SQL Server 2014' => 'SQLSysClrTypes.msi' },
        '1' => { 'Microsoft SQL Server 2014 Management Objects  (x64)' => 'SharedManagementObjects.msi' },
        'SQL' => { 'Microsoft SQL Server 2012 (64-bit)' => 'SQLEXPR_x64_ENU.exe' }
      }
      end
    end

    def self.explorers_list(version)
      case version.to_s # to_s to make sure someone didn't pass us an int
      when '9.0' then {
        'ActiveDirectory' => 'Veeam Explorer for Microsoft Active Directory',
        'SQL' => 'Veeam Explorer for Microsoft SQL Server',
        'Exchange' => 'Veeam Explorer for Microsoft Exchange',
        'SharePoint' => 'Veeam Explorer for Microsoft SharePoint',
        'Oracle' => 'Veeam Explorer for Oracle'
      }
      when '9.5' then {
        'ActiveDirectory' => 'Veeam Explorer for Microsoft Active Directory',
        'SQL' => 'Veeam Explorer for Microsoft SQL Server',
        'Exchange' => 'Veeam Explorer for Microsoft Exchange',
        'SharePoint' => 'Veeam Explorer for Microsoft SharePoint',
        'Oracle' => 'Veeam Explorer for Oracle'
      }
      end
    end
  end
end
