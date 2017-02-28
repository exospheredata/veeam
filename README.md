<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Veeam:](#veeam)
    - [_a cookbook to deploy Veeam Backup and Recovery server_](#_a-cookbook-to-deploy-veeam-backup-and-recovery-server_)
  - [Requirements](#requirements)
    - [Platforms](#platforms)
    - [Chef](#chef)
    - [Cookbooks](#cookbooks)
  - [Attributes](#attributes)
    - [Installation Media](#installation-media)
    - [Catalog](#catalog)
    - [Server](#server)
  - [Resource/Provider](#resourceprovider)
    - [Veeam_Prerequisites](#veeam_prerequisites)
      - [Actions:](#actions)
      - [Properties:](#properties)
      - [Examples:](#examples)
    - [Veeam_Catalog](#veeam_catalog)
      - [Actions:](#actions-1)
      - [Properties:](#properties-1)
      - [Examples:](#examples-1)
    - [Veeam_Console](#veeam_console)
      - [Actions:](#actions-2)
      - [Properties:](#properties-2)
      - [Examples:](#examples-2)
    - [Veeam_Server](#veeam_server)
      - [Actions:](#actions-3)
      - [Properties:](#properties-3)
      - [Examples:](#examples-3)
  - [Usage](#usage)
    - [default](#default)
    - [catalog recipe](#catalog-recipe)
    - [server recipe](#server-recipe)
    - [console recipe](#console-recipe)
    - [server_with_catalog recipe](#server_with_catalog-recipe)
    - [server_with_console recipe](#server_with_console-recipe)
    - [standalone_complete recipe](#standalone_complete-recipe)
  - [Upload to Chef Server](#upload-to-chef-server)
  - [Matchers/Helpers](#matchershelpers)
    - [Matchers](#matchers)
    - [Windows_Helper](#windows_helper)
  - [Cookbook Testing](#cookbook-testing)
    - [Before you begin](#before-you-begin)
    - [Data_bags for Test-Kitchen](#data_bags-for-test-kitchen)
    - [Rakefile and Tasks](#rakefile-and-tasks)
    - [Chefspec and Test-Kitchen](#chefspec-and-test-kitchen)
    - [Compliance Profile](#compliance-profile)
  - [Contribute](#contribute)
  - [License and Author](#license-and-author)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Veeam:
### _a cookbook to deploy Veeam Backup and Recovery server_
---
Installs and configures Veeam Backup and Recovery based on documented Veeam best practices.


## Requirements

### Platforms
- Windows Server 2012
- Windows Server 2012R2

Windows 2008R2 and lower is _not_ supported.

### Chef

- Chef 12.1+

### Cookbooks

- windows = 2.0.2


## Attributes
### Installation Media
- `node['veeam']['installer']['package_url']` - String.  Custom URL for the Veeam Backup and Recovery ISO.  Default path is 'http://download2.veeam.com/VeeamBackup&Replication_9.0.0.902.iso'
- `node['veeam']['installer']['package_checksum']` - String.  Sha256 hash of the remote ISO file.  Default value is '21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88'

### Catalog
- `node['veeam']['catalog']['install_dir']` - String. Installs the component to the specified location. By default, Veeam Backup & Replication uses the Backup Catalog subfolder in the `C:\Program Files\Veeam\Backup and Replication\` folder.
- `node['veeam']['catalog']['vm_catalogpath']` - String.  Specifies a path to the catalog folder where index files must be stored. By default, Veeam Backup & Replication uses the C:\VBRCatalog folder to store index files.
- `node['veeam']['catalog']['vbrc_service_user']` - String. Specifies a user account under which the Veeam Guest Catalog Service will run. The account must have full control NTFS permissions on the `VM_CATALOGPATH` folder where index files are stored.  If you do not specify this parameter, the Veeam Guest Catalog Service will run under the Local System account.  NOTE: The account must be in Domain\User or Computer\User format.  If using a local account, then use either the `hostname\username` or use `.\username`
- `node['veeam']['catalog']['vbrc_service_password']` - String. Specifies a password for the account under which the Veeam Guest Catalog Service will run.  This parameter must be used if you have specified the `VBRC_SERVICE_USER` parameter.
- `node['veeam']['catalog']['vbrc_service_port']` - Integer.  Specifies a TCP port that will be used by the Veeam Guest Catalog Service. By default, port number 9393 is used.
- `node['veeam']['catalog']['keep_media']` - TrueFalse.  Determines if the recipe should remove the media at the end of the installation.  Default is false

### Server
- `node['veeam']['server']['accept_eula']` - TrueFalse.  Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA.  Default = false
- `node['veeam']['server']['install_dir']` - String. Installs the component to the specified location. By default, Veeam Backup & Replication uses the Backup Catalog subfolder in the `C:\Program Files\Veeam\Backup and Replication\` folder.
- `node['veeam']['server']['vbr_license_file']` -
- `node['veeam']['server']['vbr_check_updates']` - TrueFalse. Specifies if you want Veeam Backup & Replication to automatically check for new product patches and versions.
- `node['veeam']['server']['vbr_service_user']` - String. Specifies the account under which the Veeam Backup Service will run. The account must have full control NTFS permissions on the `VBRCatalog` folder where index files are stored and the Database owner rights for the configuration database on the Microsoft SQL Server where the configuration database is deployed.  If you do not specify this parameter, the Veeam Guest Catalog Service will run under the Local System account.  NOTE: The account must be in Domain\User or Computer\User format.  If using a local account, then use either the `hostname\username` or use `.\username`
- `node['veeam']['server']['vbr_service_password']` - String. Specifies a password for the account under which the Veeam Guest Backup Service will run.  This parameter must be used if you have specified the `VBR_SERVICE_USER` parameter.
- `node['veeam']['server']['vbr_service_port']` - Integer.  Specifies a TCP port that will be used by the Veeam Guest Backup Service. By default, port number 9392 is used.
- `node['veeam']['server']['vbr_secure_connections_port']` - Integer.  Specifies an SSL port used for communication between the mount server and the backup server. By default, port 9401 is used.
- `node['veeam']['server']['vbr_sqlserver_server']` - String. Specifies a Microsoft SQL server and instance on which the configuration database will be deployed. By default, Veeam Backup & Replication uses the (local)\VEEAMSQL2012 server.  If not included or set, the recipe will install SQLExpress 2012 on the node.
- `node['veeam']['server']['vbr_sqlserver_database']` - String. Specifies a name of the configuration database to be deployed, by default, `VeeamBackup`.
- `node['veeam']['server']['vbr_sqlserver_auth']` - String. Specifies if you want to use the SQL Server authentication mode to connect to the Microsoft SQL Server where the Veeam Backup & Replication is deployed.  Supported Values are Windows or Mixed
- `node['veeam']['server']['vbr_sqlserver_username']` - String. This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a LoginID to connect to the Microsoft SQL Server in the SQL Server authentication mode.
- `node['veeam']['server']['vbr_sqlserver_password']` - String. This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a password to connect to the Microsoft SQL Server in the SQL Server authentication mode.

- `node['veeam']['server']['pf_ad_nfsdatastore']` - String. Specifies the vPower NFS root folder to which Instant VM Recovery cache will be stored. By default, the `C:\ProgramData\Veeam\Backup\NfsDatastore\` folder is used.
- `node['veeam']['server']['keep_media']` - TrueFalse.  Determines if the recipe should remove the media at the end of the installation.  Default is false

- `node['sql_server']['server_sa_password']` - String.  Configures the SQL Admin password for the SQLExpress instance.  Default value is 'Veeam1234'

## Resource/Provider

### Veeam_Prerequisites
Installs the required resoures to support Veeam applications.  Included in this resource:
- .NET Framework 4.5.2
- Microsoft SQL Server System CLR Types (x64)
- Microsoft SQL Server 2012 Management Objects (x64)
- Microsoft SQL Server 2014 (64-bit) [optional]

#### Actions:
* `:install` - Installs all of the prerequisites and optionally installs SQL Express

#### Properties:
_NOTE: properties in bold are required_
* **`package_url`** - Full URL to the installation media
* **`package_checksum`** - sha256 checksum of the installation media
* `install_sql` - Determines if SQL Express should be installed as part of adding the prerequisites.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# Install default Prerequisite tools but no SQL Express
veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  action :install
end
```

```ruby
# Install default Prerequisite tools including SQL Express
veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  install_sql true
  action :install
end
```

### Veeam_Catalog
Installs the Veeam Catalog Service

#### Actions:
* `:install` - Installs the Veeam Backup Catalog service

#### Properties:
_NOTE: properties in bold are required_
* **`package_url`** - Full URL to the installation media
* **`package_checksum`** - sha256 checksum of the installation media
* `install_dir` - Sets the install directory for the Veeam Backup Catalog service
* `vm_catalogpath` - Specifies a path to the catalog folder where index files must be stored
* `vbrc_service_user` - Specifies a user account under which the Veeam Guest Catalog Service will run
* `vbrc_service_password` - Specifies a password for the account under which the Veeam Guest Catalog Service will run
* `vbrc_service_port` - Specifies a TCP port that will be used by the Veeam Guest Catalog Service. By default, port number 9393 is used
* `keep_media` - When set to true, the downloaded ISO will not be deleted.  This is helpful if you are installing multiple services on a single node.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# A quick install of the catalog accepting all of the defaults
veeam_catalog 'Install Veeam Backup Catalog' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  action :install
end
```

```ruby
# Install of the catalog with a custom the service user set to a domain service account
veeam_catalog 'Install Veeam Backup Catalog' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  vbrc_service_user 'mydomain\_srvcuser'
  vbrc_service_password 'myPassword1'
  action :install
end
```

### Veeam_Console
Installs the Veeam Backup and Recovery Console

#### Actions:
* `:install` - Installs the Veeam Backup and Recovery Console service

#### Properties:
_NOTE: properties in bold are required_
* **`package_url`** - Full URL to the installation media
* **`package_checksum`** - sha256 checksum of the installation media
* **`accept_eula`** - Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA.  Default = false
* `install_dir` - Sets the install directory for the Veeam Backup console service
* `keep_media` - When set to true, the downloaded ISO will not be deleted.  This is helpful if you are installing multiple services on a single node.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# A quick install of the console accepting all of the defaults
veeam_console 'Install Veeam Backup console' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  accept_eula true
  action :install
end
```

```ruby
# Install of the console with to a custom installation directory
veeam_console 'Install Veeam Backup console' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  install_dir 'C:\Veeam\Console'
  accept_eula true
  action :install
end
```

### Veeam_Server
Installs the Veeam Backup and Recovery Service

#### Actions:
* `:install` - Installs the Veeam Backup and Recovery service

#### Properties:
_NOTE: properties in bold are required_
* **`package_url`** - Full URL to the installation media
* **`package_checksum`** - sha256 checksum of the installation media
* **`accept_eula`** - Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA.  Default = false
* `install_dir` - Sets the install directory for the Veeam Backup and Recovery service
* `vbr_license_file` - Future Property
* `vbr_check_updates` - Specifies if you want Veeam Backup & Replication to automatically check for new product patches and versions.
* `vbr_service_user` - Specifies a user account under which the Veeam Guest Backup Service will run
* `vbr_service_password` - Specifies a password for the account under which the Veeam Guest Backup Service will run
* `vbr_service_port` - Specifies a TCP port that will be used by the Veeam Guest Backup Service. By default, port number 9392 is used
* `vbr_secure_connections_port` - Specifies a SSL port that will be used by the Veeam Guest Backup Service. By default, port number 9401 is used
* `vbr_sqlserver_server` - Specifies a Microsoft SQL server and instance on which the configuration database will be deployed. By default, Veeam Backup & Replication uses the (local)\VEEAMSQL2012 server.  If not included or set, the recipe will install SQLExpress 2012 on the node.
* `vbr_sqlserver_database` - Specifies a name of the configuration database to be deployed, by default, `VeeamBackup`.
* `vbr_sqlserver_auth` - Specifies if you want to use the SQL Server authentication mode to connect to the Microsoft SQL Server where the Veeam Backup & Replication is deployed.  Supported Values are Windows or Mixed
* `vbr_sqlserver_username` - This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a LoginID to connect to the Microsoft SQL Server in the SQL Server authentication mode.
* `vbr_sqlserver_password` - This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a password to connect to the Microsoft SQL Server in the SQL Server authentication mode.
* `pf_ad_nfsdatastore` - Specifies the vPower NFS root folder to which Instant VM Recovery cache will be stored. By default, the `C:\ProgramData\Veeam\Backup\NfsDatastore\` folder is used.
* `keep_media` - When set to true, the downloaded ISO will not be deleted.  This is helpful if you are installing multiple services on a single node.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# A quick install of the backup service accepting the EULA and all of the defaults
veeam_server 'Install Veeam Backup Server' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  accept_eula true
  action :install
end
```

```ruby
# Install of the Backup and Recovery service with a custom the service user set to a domain service account
veeam_server 'Install Veeam Backup Catalog' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  accept_eula true
  vbr_service_user 'mydomain\_srvcuser'
  vbr_service_password 'myPassword1'
  action :install
end
```

## Usage
### default

This is an empty recipe and should _not_ be used

### catalog recipe

Installs and configures Veeam Backup and Recovery Catalog service using the default configuration including pre-requisites

### server recipe

Installs and configures Veeam Backup and Recovery Server service using the default configuration including pre-requisites and SQLExpress

### console recipe

Installs and configures Veeam Backup and Recovery Console using the default configuration including pre-requisites

### server_with_catalog recipe

Installs and configures Veeam Backup and Recovery Server & Catalog using the default configuration including pre-requisites and SQLExpress

### server_with_console recipe

Installs and configures Veeam Backup and Recovery Server & Console using the default configuration including pre-requisites and SQLExpress

### standalone_complete recipe

Installs and configures Veeam Backup and Recovery Server, Console & the Catalog service using the default configuration including pre-requisites and SQLExpress

## Upload to Chef Server
This cookbook should be included in each organization of your CHEF environment.  When importing, leverage Berkshelf:

`berks upload`

_NOTE:_ use the --no-ssl-verify switch if the CHEF server in question has a self-signed SSL certificate.

`berks upload --no-ssl-verify`

## Matchers/Helpers

### Matchers
_Note: Matchers should always be created in `libraries/matchers.rb` and used for validating calls to LWRP_

**Tests the LWRP (veeam_catalog) with an action**
* `install_veeam_catalog(resource_name)`
* `install_veeam_console(resource_name)`
* `install_veeam_server(resource_name)`
* `install_veeam_prerequisites(resource_name)`


### Windows_Helper
Testing with ChefSpec on Linux or Mac for specific Windows items such as register, Win32, etc can cause failures in the testing.  Included in this library is a helper file designed to stub and mock out these calls.

The file is located at `spec/windows_helper.rb`

## Cookbook Testing

### Before you begin
Setup your testing and ensure all dependencies are installed.  Open a terminal windows and execute:

```ruby
gem install bundler
bundle install
berks install
```

### Data_bags for Test-Kitchen

This cookbook requires the use of a data_bag for setting certain values.  Local JSON version need to be stored in the directory structure as indicated below:

```
├── chef-repo/
│   ├── cookbooks
│   │   ├── veeam
│   │   │   ├── .kitchen.yml
│   ├── data_bags
│   │   ├── data_bag_name
│   │   │   ├── data_bag_item.json

```

**Note**: Storing local testing versions of the data_bags at the root of your repo is considered best practice.  This ensures that you only need to maintain a single copy while protecting the cookbook from being accientally committed with the data_bag.  However, if you must change this location, then update the following key in the .kitchen.yml file.

```
data_bags_path: "../../data_bags/"
```

### Rakefile and Tasks
This repo includes a **Rakefile** for common tasks

| Task Command | Description |
| ------------- |-------------|
| **rake** | Run Style, Foodcritic, Maintainers, and Unit Tests |
| **rake style** | Run all style checks |
| **rake style:chef** | Run Chef style checks |
| **rake style:ruby** | Run Ruby style checks |
| **rake style:ruby:auto_correct** | Auto-correct RuboCop offenses |
| **rake unit** | Run ChefSpec examples |
| **rake integration** | Run all kitchen suites |
| **rake integration:kitchen:catalog-windows-2012r2** | Run catalog-windows-2012r2 test instance |
| **rake integration:kitchen:console-windows-2012r2** | Run console-windows-2012r2 test instance |
| **rake integration:kitchen:server-windows-2012r2** | Run server-windows-2012r2 test instance |
| **rake integration:kitchen:server-with-catalog-windows-2012r2** | Run server-with-catalog-windows-2012r2 test instance |
| **rake integration:kitchen:server-with-console-windows-2012r2** | Run server-with-console-windows-2012r2 test instance |
| **rake integration:kitchen:standalone-complete-windows-2012r2** | Run standalone-complete-windows-2012r2 test instance |
| **rake maintainers:generate** | Generate MarkDown version of MAINTAINERS file |

### Chefspec and Test-Kitchen

1. `bundle install`: Installs and pulls all ruby gems dependencies from the Gemfile.

2. `berks install`: Installs all cookbook dependencies based on the [Berksfile](Berksfile) and the [metadata.rb](metadata.rb)

3. `rake`: This will run all of the local tests - syntax, lint, unit, and maintainers file.
4. `rake integration`: This will run all of the kitchen tests

### Compliance Profile
Included in this cookbook is a set of Inspec profile tests used for the Windows 2012 and greater Test-Kitchen.  These profiles can also be loaded into Chef Compliance to ensure on-going validation.  The Control files are located at `test/inspec/suite_name`

## Contribute
 - Fork it
 - Create your feature branch (git checkout -b my-new-feature)
 - Commit your changes (git commit -am 'Add some feature')
 - Push to the branch (git push origin my-new-feature)
 - Create new Pull Request

## License and Author

- Author:: Jeremy Goodrum ([jeremy@exospheredata.com](mailto:jeremy@exospheredata.com))

```text
The MIT License

Copyright (c) 2016 Exosphere Data, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
