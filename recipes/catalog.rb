#
# Cookbook Name:: veeam
# Recipe:: server
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

if node['platform_version'].to_f >= '6.1'.to_f # '6.1.' is the numeric platform_version for Windows 2008R2

  # Veeam requires MS .NET 4.5.2
  node.override['ms_dotnet']['v4']['version'] = '4.5.2'
  node.override['ms_dotnet']['v4']['perform_reboot'] = true
  include_recipe('ms_dotnet::ms_dotnet4')

  veeam_catalog 'Install Veeam Backup Catalog' do
    package_url 'http://192.168.33.10/software/veeam/VeeamBackup&Replication_9.0.0.902.iso'
    package_checksum '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'
    action :install
  end
else
  Chef::Log.warn('This recipe requires a Windows 2008R2 or higher host!')
  raise 'This recipe requires a Windows 2008R2 or higher host!'
end
