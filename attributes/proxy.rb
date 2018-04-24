#
# Cookbook Name:: veeam
# Attributes:: proxy
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['proxy']['vbr_server']     = nil
default['veeam']['proxy']['vbr_port']       = 9392
default['veeam']['proxy']['vbr_username']   = nil
default['veeam']['proxy']['vbr_password']   = nil

default['veeam']['proxy']['proxy_username'] = nil
default['veeam']['proxy']['proxy_password'] = nil

default['veeam']['proxy']['description']    = nil

default['veeam']['proxy']['max_tasks']      = 2
default['veeam']['proxy']['transport_mode'] = 'Auto'

default['veeam']['proxy']['use_ip_address'] = false
default['veeam']['proxy']['register']       = true
