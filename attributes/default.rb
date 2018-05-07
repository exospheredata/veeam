#
# Cookbook Name:: veeam
# Attributes:: default
#
# Copyright (c) 2017 Exosphere Data LLC, All Rights Reserved.

default['veeam']['version'] = '9.5'
default['veeam']['installer']['package_url'] = nil # Local or custom URL location for ISO
default['veeam']['installer']['package_checksum'] = nil # Sha256 checksum of ISO
default['veeam']['license_url'] = nil
default['veeam']['installer']['update_url'] = node['veeam']['installer']['package_url'] # Local or custom URL location for ISO
default['veeam']['installer']['update_checksum'] = node['veeam']['installer']['package_checksum'] # Sha256 checksum of ISO

default['veeam']['build'] = if node['veeam']['installer']['update_url'].nil? && node['veeam']['installer']['package_url'].nil?
                              node['veeam']['version']
                            elsif node['veeam']['installer']['update_url'] == node['veeam']['installer']['package_url']
                              /(\d+.\d+.\d+.\d+)/.match(node['veeam']['installer']['package_url'].split('/')[-1]).captures[0]
                            else
                              /(\d+.\d+.\d+.\d+)/.match(node['veeam']['installer']['update_url'].split('/')[-1]).captures[0]
                            end
default['veeam']['reboot_on_upgrade'] = true
default['veeam']['upgrade']['keep_media'] = false
