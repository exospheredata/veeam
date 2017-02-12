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
    package_url node['veeam']['installer']['package_url']
    package_checksum node['veeam']['installer']['package_checksum']
    install_dir node['veeam']['catalog']['install_dir']
    vm_catalogpath node['veeam']['catalog']['vm_catalogpath']
    vbrc_service_user node['veeam']['catalog']['vbrc_service_user']
    vbrc_service_password node['veeam']['catalog']['vbrc_service_password']
    vbrc_service_port node['veeam']['catalog']['vbrc_service_port']
    keep_media node['veeam']['catalog']['keep_media']
    action :install
  end
else
  Chef::Log.warn('This recipe requires a Windows 2008R2 or higher host!')
  raise 'This recipe requires a Windows 2008R2 or higher host!'
end
