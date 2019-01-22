#
# Cookbook Name:: veeam
# Recipe:: prerequisites
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

error_message = 'This recipe requires a Windows 2012 or higher host!'

# If this host is not Windows, then abort
raise ArgumentError, error_message unless node['platform'] == 'windows'

# If this host is older than Windows 2012, we should abort the process for an unsupported platform
raise ArgumentError, error_message if node['platform_version'].to_f < '6.2.9200'.to_f # '6.2.9200' is the numeric platform_version for Windows 2012

veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['build']
  install_sql true
  action :install
end
