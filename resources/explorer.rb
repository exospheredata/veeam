# Cookbook Name:: veeam
# Resource:: explorer
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.1.0
# Date:: 2017-02-07
#
# Copyright (c) 2016 Exosphere Data LLC, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default_action :install

property :package_name, String
property :share_path, String

property :package_url, String
property :package_checksum, String

property :version, String, required: true
property :keep_media, [TrueClass, FalseClass], default: false

property :explorers, Array, required: true

# We need to include the windows helpers to keep things dry
::Chef::Provider.send(:include, Windows::Helper)
::Chef::Provider.send(:include, Veeam::Helper)

action :install do
  check_os_version(node)

  raise 'The Veeam Backup and Replication Server must be installed before you can install Veeam Explorers' unless is_package_installed?('Veeam Backup & Replication Server')
  raise 'The Veeam Backup and Replication Console must be installed before you can install Veeam Explorers' unless is_package_installed?('Veeam Backup & Replication Console')

  # Call the Veeam::Helper to find the correct URL based on the version of the Veeam Backup and Replication edition passed
  # as an attribute.
  unless new_resource.package_url
    new_resource.package_url = find_package_url(new_resource.version)
    new_resource.package_checksum = find_package_checksum(new_resource.version)
    Chef::Log.info(new_resource.package_url)
  end

  # Halt this process now.  There is no URL for the package.
  raise ArgumentError, 'You must provide a package URL or choose a valid version' unless new_resource.package_url

  # Determine if all of the Veeam Explorers are installed and if so, then skip the processing.
  installed_explorers = []
  explorers_list = explorers_list(new_resource.version)

  new_resource.explorers.each do |explorer|
    installed_explorers.push(explorer) if is_package_installed?(explorers_list[explorer])
  end

  # Compare the required Explorers with those installed.  If all are installed, then
  # we should report no change back.  By returning 'false', Chef will report that the resource is up-to-date.
  return false if (new_resource.explorers - installed_explorers).empty?

  package_save_dir = win_friendly_path(::File.join(::Chef::Config[:file_cache_path], 'package'))

  # This will only create the directory if it does not exist which is likely the case if we have
  # never performed a remote_file install.
  directory package_save_dir do
    action :create
  end

  # Since we are passing a URL, it is important that we handle the pull of the file as well as extraction.
  # We likely will receive an ISO but it is possible that we will have a ZIP or other compressed file type.
  # This is easy to handle as long as we add a method to check for the file base type.

  Chef::Log.debug('Downloading Veeam Backup and Replication software via URL')
  package_name = new_resource.package_url.split('/').last
  installer_file_name = win_friendly_path(::File.join(package_save_dir, package_name))
  iso_installer(installer_file_name, new_resource)

  # We need to delay the evaluation of this so that we can properly get the value during run time.
  ruby_block 'Install Veeam Explorers' do
    block do
      install_media_path = get_media_installer_location(installer_file_name)
      veeam_explorer_root = "#{install_media_path}\\Explorers"

      new_resource.explorers.each do |explorer|
        Chef::Log.debug "Installing Veeam Explorer for #{explorers_list[explorer]}... begin"
        windows_package explorers_list[explorer] do
          provider       Chef::Provider::Package::Windows
          source         "#{veeam_explorer_root}\\VeeamExplorerFor#{explorer}.msi"
          installer_type :msi
          action         :install
        end
        Chef::Log.debug "Installing Veeam Explorer for #{explorers_list[explorer]}... success"
      end
    end
  end

  unmount_installer(installer_file_name)

  # If the 'keep_media' property is True, we should report our success but skip the file deletion code below.
  return if new_resource.keep_media

  # Since the property 'keep_media' was set to false, we will need to remove it

  # We will want to remove the tmp downloaded file later to save space
  file installer_file_name do
    backup false
    action :delete
  end
end

action_class do
  def whyrun_supported?
    true
  end
end
