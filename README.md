<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Veeam:](#veeam)
  - [Requirements](#requirements)
    - [Platforms](#platforms)
    - [Chef](#chef)
    - [Cookbooks](#cookbooks)
  - [Attributes](#attributes)
    - [Installation Media](#installation-media)
    - [Catalog](#catalog)
  - [Usage](#usage)
    - [default](#default)
    - [catalog recipe](#catalog-recipe)
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
- ms_dotnet = 3.1.0


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


## Usage
### default

This is an empty recipe and should _not_ be used

### catalog recipe

Installs and configures Veeam Backup and Recovery Catalog service using the default configuration

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
