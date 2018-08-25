#
# Cookbook:: veeam
# Recipe:: host_mgmt
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2018, Exosphere Data, LLC, All Rights Reserved.

error_message = 'This recipe requires a Windows 2012 or higher host!'

# If this host is not Windows, then abort
raise ArgumentError, error_message unless node['platform'] == 'windows'

# If this host is older than Windows 2012, we should abort the process for an unsupported platform
raise ArgumentError, error_message if node['platform_version'].to_f < '6.2.9200'.to_f # '6.2.9200' is the numeric platform_version for Windows 2012

veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['version']
  install_sql false
  action :install
end

veeam_console 'Install Veeam Backup console' do
  package_url node['veeam']['installer']['package_url']
  package_checksum node['veeam']['installer']['package_checksum']
  version node['veeam']['version']
  accept_eula node['veeam']['console']['accept_eula']
  install_dir node['veeam']['console']['install_dir']
  keep_media true
  action :install
end

veeam_upgrade node['veeam']['build'] do
  package_url node['veeam']['installer']['update_url']
  package_checksum node['veeam']['installer']['update_checksum']
  keep_media node['veeam']['upgrade']['keep_media']
  auto_reboot node['veeam']['reboot_on_upgrade']
  action :install
end

unless node['veeam']['host']['server'].nil?
  veeam_host node['veeam']['host']['server'] do
    vbr_server      node['veeam']['host']['vbr_server']
    vbr_server_port node['veeam']['host']['vbr_port']
    vbr_username    node['veeam']['host']['vbr_username']
    vbr_password    node['veeam']['host']['vbr_password']
    host_username   node['veeam']['host']['host_username']
    host_password   node['veeam']['host']['host_password']
    description     node['veeam']['host']['description']
    host_type       node['veeam']['host']['type']
    action          node['veeam']['host']['action'].to_sym
    only_if { !node['veeam']['host']['server'].nil? }
  end
end
