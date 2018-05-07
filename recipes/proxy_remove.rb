#
# Cookbook:: veeam
# Recipe:: proxy_remove
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
  action :remove
end
