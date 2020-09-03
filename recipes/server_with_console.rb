#
# Cookbook:: veeam
# Recipe:: server_with_console
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2020, Exosphere Data, LLC, All Rights Reserved.

error_message = 'This recipe requires a Windows 2012 or higher host!'

# If this host is not Windows, then abort
raise ArgumentError, error_message unless platform_family?('windows')

# If this host is older than Windows 2012, we should abort the process for an unsupported platform
raise ArgumentError, error_message if node['platform_version'].to_f < '6.2.9200'.to_f # '6.2.9200' is the numeric platform_version for Windows 2012

veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['build']
  install_sql true
  action :install
end

veeam_server 'Install Veeam Backup Server' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['build']
  accept_eula node['veeam']['server']['accept_eula']
  evaluation node['veeam']['server']['evaluation']
  install_dir node['veeam']['server']['install_dir']
  vbr_sqlserver_server node['veeam']['server']['vbr_sqlserver_server']
  vbr_service_user node['veeam']['server']['vbr_service_user']
  vbr_service_password node['veeam']['server']['vbr_service_password']
  vbr_service_port node['veeam']['server']['vbr_service_port']
  keep_media true
  action :install
end

veeam_console 'Install Veeam Backup Console' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['build']
  accept_eula node['veeam']['console']['accept_eula']
  install_dir node['veeam']['console']['install_dir']
  keep_media true
  action :install
end

veeam_explorer 'Install Veeam Backup Explorers' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['build']
  explorers node['veeam']['server']['explorers']
  keep_media true
  action :install
end

veeam_upgrade node['veeam']['build'] do
  package_url node['veeam']['installer']['update_url']
  package_checksum node['veeam']['installer']['update_checksum']
  keep_media node['veeam']['upgrade']['keep_media'] || node['veeam']['console']['keep_media'] || node['veeam']['server']['keep_media']
  auto_reboot node['veeam']['reboot_on_upgrade']
  action :install
end
