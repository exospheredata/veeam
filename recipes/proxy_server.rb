#
# Cookbook:: veeam
# Recipe:: proxy_server
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

%w(FS-FileServer Print-Server).each do |feature|
  windows_feature feature do
    install_method :windows_feature_powershell
    action :install
  end
end

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
  action :install
end

proxy_server = if node['veeam']['proxy']['use_ip_address']
                 node['ipaddress']
               else
                 node['hostname']
               end

veeam_proxy proxy_server do
  vbr_server      node['veeam']['proxy']['vbr_server']
  vbr_server_port node['veeam']['proxy']['vbr_port']
  vbr_username    node['veeam']['proxy']['vbr_username']
  vbr_password    node['veeam']['proxy']['vbr_password']
  proxy_username  node['veeam']['proxy']['proxy_username']
  proxy_password  node['veeam']['proxy']['proxy_password']
  description     node['veeam']['proxy']['description']
  max_tasks       node['veeam']['proxy']['max_tasks']
  transport_mode  node['veeam']['proxy']['transport_mode']
  action :add
  only_if { node['veeam']['proxy']['register'] }
end
