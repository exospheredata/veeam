#
# Cookbook Name:: veeam
# Recipe:: console
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

if node['platform_version'].to_f >= '6.1'.to_f # '6.1.' is the numeric platform_version for Windows 2008R2

  veeam_prerequisites 'Install Veeam Prerequisites' do
    package_url node['veeam']['installer']['package_url']
    package_checksum node['veeam']['installer']['package_checksum']
    version node['veeam']['version']
    action :install
  end

  veeam_console 'Install Veeam Backup console' do
    package_url node['veeam']['installer']['package_url']
    package_checksum node['veeam']['installer']['package_checksum']
    version node['veeam']['version']
    accept_eula node['veeam']['console']['accept_eula']
    install_dir node['veeam']['console']['install_dir']
    keep_media node['veeam']['console']['keep_media']
    action :install
  end
else
  Chef::Log.warn('This recipe requires a Windows 2008R2 or higher host!')
  raise 'This recipe requires a Windows 2008R2 or higher host!'
end
