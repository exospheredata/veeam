#
# Cookbook Name:: veeam
# Attributes:: default
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['version'] = '9.0'
default['veeam']['installer']['package_url'] = nil # Local or custom URL location for ISO
default['veeam']['installer']['package_checksum'] = nil # Sha256 checksum of ISO
default['veeam']['license_url'] = nil
