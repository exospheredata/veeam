#
# Cookbook Name:: veeam
# Recipe:: server
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

if node['platform_version'].to_f >= '6.1'.to_f # '6.1.' is the numeric platform_version for Windows 2008R2

  veeam_prerequisites 'Install Veeam Prerequisites' do
    package_url node['veeam']['installer']['package_url']
    package_checksum node['veeam']['installer']['package_checksum']
    version node['veeam']['version']
    install_sql true
    action :install
  end

  veeam_server 'Install Veeam Backup Server' do
    package_url node['veeam']['installer']['package_url']
    package_checksum node['veeam']['installer']['package_checksum']
    version node['veeam']['version']
    accept_eula node['veeam']['server']['accept_eula']
    evaluation node['veeam']['server']['evaluation']
    install_dir node['veeam']['server']['install_dir']
    vbr_service_user node['veeam']['server']['vbr_service_user']
    vbr_service_password node['veeam']['server']['vbr_service_password']
    vbr_service_port node['veeam']['server']['vbr_service_port']
    keep_media node['veeam']['server']['keep_media']
    action :install
  end
else
  Chef::Log.warn('This recipe requires a Windows 2008R2 or higher host!')
  raise 'This recipe requires a Windows 2008R2 or higher host!'
end
