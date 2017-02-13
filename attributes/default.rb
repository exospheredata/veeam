#
# Cookbook Name:: veeam
# Attributes:: default
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['installer']['package_url'] = 'http://download2.veeam.com/VeeamBackup&Replication_9.0.0.902.iso'
default['veeam']['installer']['package_checksum'] = '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'

default['veeam']['catalog']['install_dir'] = 'C:\\Program Files\\Veeam\\Backup and Replication\\'
default['veeam']['catalog']['vm_catalogpath'] = nil
default['veeam']['catalog']['vbrc_service_user'] = nil
default['veeam']['catalog']['vbrc_service_password'] = nil
default['veeam']['catalog']['vbrc_service_port'] = nil
default['veeam']['catalog']['keep_media'] = false
