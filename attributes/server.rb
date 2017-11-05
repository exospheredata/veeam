#
# Cookbook Name:: veeam
# Attributes:: server
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['server']['accept_eula'] = false
default['veeam']['server']['install_dir'] = 'C:\\Program Files\\Veeam\\Backup and Replication\\'
default['veeam']['server']['evaluation'] = true
default['veeam']['server']['vbr_check_updates'] = false
# VBR Service Configuration
default['veeam']['server']['vbr_service_user'] = nil
default['veeam']['server']['vbr_service_password'] = nil
default['veeam']['server']['vbr_service_port'] = nil
default['veeam']['server']['vbr_secure_connections_port'] = nil
# SQL Server Connection Details
default['veeam']['server']['vbr_sqlserver_server'] = nil
default['veeam']['server']['vbr_sqlserver_database'] = nil
default['veeam']['server']['vbr_sqlserver_auth'] = nil
default['veeam']['server']['vbr_sqlserver_username'] = nil
default['veeam']['server']['vbr_sqlserver_password'] = nil

default['veeam']['server']['pf_ad_nfsdatastore'] = nil
default['veeam']['server']['keep_media'] = false

default['sql_server']['server_sa_password'] = 'Veeam1234'

# Install all of the explorers by default.  New explorers shoudl be included in the libraries/helper.rb file
default['veeam']['server']['explorers'] = %w(ActiveDirectory Exchange SQL Oracle SharePoint)
