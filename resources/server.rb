# Cookbook Name:: veeam
# Resource:: server
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.1.0
# Date:: 2017-02-13
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

actions :install

default_action :install

attribute :package_name, kind_of: String
attribute :share_path, kind_of: String

attribute :package_url, kind_of: String
attribute :package_checksum, kind_of: String

attribute :accept_eula, kind_of: [TrueClass, FalseClass], default: false, required: true
attribute :install_dir, kind_of: String
attribute :vbr_license_file, kind_of: String
attribute :vbr_check_updates, [Integer, TrueClass, FalseClass]

# VBR Service Configuration
attribute :vbr_service_user, kind_of: String
attribute :vbr_service_password, kind_of: String
attribute :vbr_service_port, kind_of: Integer
attribute :vbr_secure_connections_port, kind_of: Integer

# SQL Server Connection Details
attribute :vbr_sqlserver_server, kind_of: String
attribute :vbr_sqlserver_database, kind_of: String
attribute :vbr_sqlserver_auth, kind_of: String, equal_to: %w(Windows Mixed)
attribute :vbr_sqlserver_username, kind_of: String
attribute :vbr_sqlserver_password, kind_of: String

# Specifies the vPower NFS root folder to which Instant VM Recovery cache will be stored
attribute :pf_ad_nfsdatastore, kind_of: String

attribute :keep_media, kind_of: [TrueClass, FalseClass], default: false
