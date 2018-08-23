#
# Cookbook Name:: veeam
# Attributes:: host
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['host']['vbr_server']    = nil
default['veeam']['host']['vbr_port']      = 9392
default['veeam']['host']['vbr_username']  = nil
default['veeam']['host']['vbr_password']  = nil

default['veeam']['host']['host_username'] = nil
default['veeam']['host']['host_password'] = nil

default['veeam']['host']['description']   = nil

default['veeam']['host']['server']        = nil
default['veeam']['host']['type']          = nil

default['veeam']['host']['action']        = 'add'
supported_host_actions                    = %w(add remove)
raise ArgumentError, "Invalid value assigned to attribute (node['veeam']['host']['action']): #{node['veeam']['host']['action']}.  Valid values are #{supported_host_actions.join(',')}" unless %w(add remove).include?(node['veeam']['host']['action'])
