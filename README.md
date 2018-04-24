# Veeam:
### _a cookbook to deploy Veeam Backup and Replication server_
---
This cookbook installs and configures Veeam Backup and Replication based on documented Veeam best practices.  The cookbook includes recipes to deploy all components of the solution as well as the optional Explorers.

_Note: Veeam prerequisites requires that Microsoft .NET Framework 4.5.2 be installed on the host.  As part of the installation, a reboot is required and will automatically be handled by the resource_

## Table of Contents
*generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Requirements](#requirements)
  - [Platforms](#platforms)
  - [Chef](#chef)
  - [Cookbooks](#cookbooks)
- [Attributes](#attributes)
  - [Installation Media](#installation-media)
  - [Upgrade Details](#upgrade-details)
  - [Catalog](#catalog)
  - [Server](#server)
  - [Console](#console)
  - [Proxy](#proxy)
- [Veeam Media and Licenses](#veeam-media-and-licenses)
  - [Veeam Backup and Replication ISO](#veeam-backup-and-replication-iso)
  - [Veeam Backup and Replication Update Zip files](#veeam-backup-and-replication-update-zip-files)
  - [Veeam Backup and Replication License file](#veeam-backup-and-replication-license-file)
- [Veeam Upgrade Procedures and Details](#veeam-upgrade-procedures-and-details)
  - [Configuring the Updates](#configuring-the-updates)
  - [Upgrade Process and Warnings](#upgrade-process-and-warnings)
  - [Recipes that perform automatic upgrades](#recipes-that-perform-automatic-upgrades)
- [Resource/Provider](#resourceprovider)
  - [Veeam_Prerequisites](#veeam_prerequisites)
  - [Veeam_Catalog](#veeam_catalog)
  - [Veeam_Console](#veeam_console)
  - [Veeam_Server](#veeam_server)
  - [Veeam_Explorer](#veeam_explorer)
  - [Veeam_Upgrade](#veeam_upgrade)
  - [Veeam_Proxy](#veeam_proxy)
- [Usage](#usage)
  - [default](#default)
  - [catalog recipe](#catalog-recipe)
  - [server recipe](#server-recipe)
  - [console recipe](#console-recipe)
  - [server_with_catalog recipe](#server_with_catalog-recipe)
  - [server_with_console recipe](#server_with_console-recipe)
  - [standalone_complete recipe](#standalone_complete-recipe)
  - [proxy recipe](#proxy-recipe)
  - [proxy_remove recipe](#proxy_remove-recipe)
  - [upgrade recipe](#upgrade-recipe)
- [Upload to Chef Server](#upload-to-chef-server)
- [Matchers/Helpers](#matchershelpers)
  - [Matchers](#matchers)
  - [Veeam::Helper](#veeamhelper)
  - [Windows_Helper](#windows_helper)
- [Cookbook Testing](#cookbook-testing)
  - [Before you begin](#before-you-begin)
  - [Data_bags for Test-Kitchen](#data_bags-for-test-kitchen)
  - [Rakefile and Tasks](#rakefile-and-tasks)
  - [Chefspec and Test-Kitchen](#chefspec-and-test-kitchen)
  - [Compliance Profile](#compliance-profile)
- [Contribute](#contribute)
- [License and Author](#license-and-author)

## Requirements

### Platforms
- Windows Server 2012
- Windows Server 2012R2
- Windows Server 2016

Windows 2008R2 and lower is _not_ supported.

#### _Note regarding SQL Express Requirements:_
The installation of SQL Express requires that a temporary Scheduled Task be created within Windows to perform the installation.  The reason for this workaround is due to a known limitation with Microsoft SQL installations via remote powershell executions.  This enhancement has been added to allow for the ability to perform the installation via Terraform, Knife Bootstrap, or any other remote powershell based execution process.

### Chef

- Chef 12.5+

### Cookbooks

- windows


## Attributes
### Installation Media
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['version']` | String. | Base version of Veeam to install and used to download the appropriate ISO.  Supported versions are '9.0' and '9.5' | '9.5' | |
| `node['veeam']['installer']['package_url']` | String. | Custom URL for the Veeam Backup and Replication ISO. If not provided, then the ISO will be downloaded directly from Veeam | nil | |
| `node['veeam']['installer']['package_checksum']` | String. | Sha256 hash of the remote ISO file. Required when setting the `node['veeam']['installer']['package_url']`| nil | |
| `node['veeam']['license_url']` | String. | URL for downloading the license filed used by this server.  If not provided, the [license data_bag](#veeam-backup-and-replication-license-file) will be checked or the software will be installed in evaluation mode. | nil | |

### Upgrade Details
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['installer']['update_url']` | String. | Custom URL for the Veeam Backup and Replication ISO or Upgrade ZIP. If not provided, then the `node['veeam']['installer']['package_url']` will be used.  | nil | |
| `node['veeam']['installer']['update_checksum']` | String. | Sha256 hash of the remote ISO or ZIP file.  Required when setting the `node['veeam']['installer']['update_url']` | nil |
| `node['veeam']['build']` | String | Current Veeam Build ID to be used when performing upgrades.  Will default to the value of the build found in the attribute `node['veeam']['installer']['update_url']` unless not set.  If no `node['veeam']['installer']['update_url']` provided then the value of the Build in `node['veeam']['installer']['package_url']` will be used.  Otherwise, the Value of the `node['veeam']['version']` will be assigned. | Multi | |
| `node['veeam']['reboot_on_upgrade']` | TrueFalse | When performing an upgrade, the Veeam process will sometimes require a reboot.  This key will control if the reboot should be automatically performed at the end of the upgrade. | true | |
| `node['veeam']['upgrade']['keep_media']` | TrueFalse | Determines if the recipe should keep the media at the end of the upgrade. | false | |

### Catalog
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['catalog']['install_dir']` | String. | Installs the component to the specified location. By default, Veeam Backup & Replication uses the Backup Catalog subfolder in the `C:\Program Files\Veeam\Backup and Replication\` folder. | C:\Program Files\Veeam\Backup and Replication\ | |
| `node['veeam']['catalog']['vm_catalogpath']` | String. |  Specifies a path to the catalog folder where index files must be stored. By default, Veeam Backup & Replication uses the C:\VBRCatalog folder to store index files. | C:\VBRCatalog | |
| `node['veeam']['catalog']['vbrc_service_user']` | String. | Specifies a user account under which the Veeam Guest Catalog Service will run. The account must have full control NTFS permissions on the `VM_CATALOGPATH` folder where index files are stored.  If you do not specify this parameter, the Veeam Guest Catalog Service will run under the Local System account.  NOTE: The account must be in Domain\User or Computer\User format.  If using a local account, then use either the `hostname\username` or use `.\username` | nil | |
| `node['veeam']['catalog']['vbrc_service_password']` | String. | Specifies a password for the account under which the Veeam Guest Catalog Service will run.  This parameter must be used if you have specified the `VBRC_SERVICE_USER` parameter. | nil | |
| `node['veeam']['catalog']['vbrc_service_port']` | Integer. | Specifies a TCP port that will be used by the Veeam Guest Catalog Service. By default, port number 9393 is used. | 9393 | |
| `node['veeam']['catalog']['keep_media']` | TrueFalse. | Determines if the recipe should keep the media at the end of the installation. | false | |

### Server
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['server']['accept_eula']` | TrueFalse |  Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA. | false | X |
| `node['veeam']['server']['install_dir']` | String | Installs the component to the specified location. By default, Veeam Backup & Replication uses the Backup Server subfolder in the `C:\Program Files\Veeam\Backup and Replication\` folder. | C:\Program Files\Veeam\Backup and Replication\ | |
| `node['veeam']['server']['evaluation']` | TrueFalse | Determines if the Veeam Backup and Replication server should be installed using Evaluation Mode or if a license should be attached.  Default value is true and the server will be installed with no license. | true | |
| `node['veeam']['server']['vbr_check_updates']` | TrueFalse | Specifies if you want Veeam Backup & Replication to automatically check for new product patches and versions. | false | |
| `node['veeam']['server']['vbr_service_user']` | String | Specifies the account under which the Veeam Backup Service will run. The account must have full control NTFS permissions on the `VBRCatalog` folder where index files are stored and the Database owner rights for the configuration database on the Microsoft SQL Server where the configuration database is deployed.  If you do not specify this parameter, the Veeam Guest Catalog Service will run under the Local System account.  NOTE: The account must be in Domain\User or Computer\User format.  If using a local account, then use either the `hostname\username` or use `.\username` | Local System | |
| `node['veeam']['server']['vbr_service_password']` | String | Specifies a password for the account under which the Veeam Guest Backup Service will run.  This parameter must be used if you have specified the `VBR_SERVICE_USER` parameter. | nil | |
| `node['veeam']['server']['vbr_service_port']` | Integer | Specifies a TCP port that will be used by the Veeam Guest Backup Service. By default, port number 9392 is used. | 9392 | |
| `node['veeam']['server']['vbr_secure_connections_port']` | Integer | Specifies an SSL port used for communication between the mount server and the backup server. By default, port 9401 is used. | 9401 | |
| `node['veeam']['server']['vbr_sqlserver_server']` | String | Specifies a Microsoft SQL server and instance on which the configuration database will be deployed. By default, Veeam Backup & Replication uses the (local)\VEEAMSQL2012 server.  If not included or set, the recipe will install SQLExpress 2012 on the node. | nil | |
| `node['veeam']['server']['vbr_sqlserver_database']` | String | Specifies a name of the configuration database to be deployed. | VeeamBackup | |
| `node['veeam']['server']['vbr_sqlserver_auth']` | String | Specifies if you want to use the SQL Server authentication mode to connect to the Microsoft SQL Server where the Veeam Backup & Replication is deployed.  Supported Values are Windows or Mixed | nil | |
| `node['veeam']['server']['vbr_sqlserver_username']` | String | This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a LoginID to connect to the Microsoft SQL Server in the SQL Server authentication mode. | nil | |
| `node['veeam']['server']['vbr_sqlserver_password']` | String | This parameter must be used if you have specified the `VBR_SQLSERVER_AUTHENTICATION` parameter.  Specifies a password to connect to the Microsoft SQL Server in the SQL Server authentication mode. | nil | |
| `node['veeam']['server']['pf_ad_nfsdatastore']` | String | Specifies the vPower NFS root folder to which Instant VM Recovery cache will be stored. | C:\ProgramData\Veeam\Backup\NfsDatastore\ | |
| `node['veeam']['server']['keep_media']` | TrueFalse |  Determines if the recipe should keep the media at the end of the installation. | false | |
| `node['sql_server']['server_sa_password']` | String | Configures the SQL Admin password for the SQLExpress instance. | 'Veeam1234' | |
| `node['veeam']['server']['explorers']` | Array. List of Veeam Explorers to install. | 'ActiveDirectory','Exchange','SQL','Oracle','SharePoint' | |

### Console
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['console']['accept_eula']` | TrueFalse | Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA. | false | X |
| `node['veeam']['console']['install_dir']` | String | Installs the component to the specified location. By default, Veeam Backup & Replication uses the Backup Console subfolder in the `C:\Program Files\Veeam\Backup and Replication\` folder. | C:\Program Files\Veeam\Backup and Replication\ | |
| `node['veeam']['console']['keep_media']` | TrueFalse | Determines if the recipe should keep the media at the end of the installation. | false | |

### Proxy
| Attribute | Type | Description | Default Value | Mandatory |
| --- | --- | --- | --- | --- |
| `node['veeam']['proxy']['vbr_server']` | String | DNS or IP Address of the Veeam Backup and Replication Server |  | X |
| `node['veeam']['proxy']['vbr_port']` | String | Veeam Backup and Replication Server Port | 9392 | |
| `node['veeam']['proxy']['vbr_username']` | String | Username with permissions to add Servers and Proxies within Veeam Backup and Replication server |  | X |
| `node['veeam']['proxy']['vbr_password']` | String | Password for the user provided |  | X |
| `node['veeam']['proxy']['proxy_username']` | String | Required when Adding a new Proxy.  Username with Access to the Proxy Server.  Will generate a new set of credentials within Veeam Backup and Replication server if none exist.|  | X |
| `node['veeam']['proxy']['proxy_password']` | String | Required when Adding a new Proxy.  Password for the user provided.|  | = nil
| `node['veeam']['proxy']['description']` | String | Description for the Proxy Server.  Will automatically start with "ADDED by CHEF: ".  Defaults to "ADDED by CHEF: Proxy Server" |  | X |
| `node['veeam']['proxy']['max_tasks']` | String | Specifies the number of concurrent tasks that can be assigned to the proxy simultaneously. Permitted values: 1-100 | 2 | X |
| `node['veeam']['proxy']['transport_mode']` | String | Specifies the transport mode used by the backup proxy.  Supported Values 'Auto','DirectStorageAccess','HotAdd','Nbd' | 'Auto' | X |
| `node['veeam']['proxy']['use_ip_address']` | String | Register to Veeam using the host IP and not the Hostname. | false | |
| `node['veeam']['proxy']['register']` | String | Determines if the proxy_server recipe should initiate a Proxy registration | true | |

## Veeam Media and Licenses

### Veeam Backup and Replication ISO
The attribute `node['veeam']['version']` is used to evaluate the ISO download path and checksum for the installation media.  When provided, the version selected will be downloaded based on the value found in `libraries/helper.rb`.  This media path can be overridden by providing the appropriate installation media attributes - `node['veeam']['installer']['package_url']` and `node['veeam']['installer']['package_checksum']`.  By default, these attributes are `nil` and the system will download the ISO every time.

| Version | ISO URL | SHA256 |
| ------------- |-------------|-------------|
| **9.0** | [VeeamBackup&Replication_9.0.0.902.iso](http://download.veeam.com/VeeamBackup&Replication_9.0.0.902.iso) | 21f9d2c318911e668511990b8bbd2800141a7764cc97a8b78d4c2200c1225c88 |
| **9.5** | [VeeamBackup&Replication_9.5.0.711.iso](http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso) | af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00 |
| **9.5.0.711** | [VeeamBackup&Replication_9.5.0.711.iso](http://download.veeam.com/VeeamBackup&Replication_9.5.0.711.iso) | af3e3f6db9cb4a711256443894e6fb56da35d48c0b2c32d051960c52c5bc2f00 |
| **9.5.0.1038** | [VeeamBackup&Replication_9.5.0.1038.Update2.iso](http://download.veeam.com/VeeamBackup&Replication_9.5.0.1038.Update2.iso) | 180b142c1092c89001ba840fc97158cc9d3a37d6c7b25c93a311115b33454977 |
| **9.5.0.1536** | [VeeamBackup&Replication_9.5.0.1536.Update3.iso](http://download.veeam.com/VeeamBackup&Replication_9.5.0.1536.Update3.iso) | 5020ef015e4d9ff7070d43cf477511a2b562d8044975552fd08f82bdcf556a43 |


### Veeam Backup and Replication Update Zip files
The attribute `node['veeam']['build']` is used to evaluate the Zip download path and checksum for the installation media.  When provided, the build selected will be downloaded based on the value found in `libraries/helper.rb`.  This media path can be overridden by providing the appropriate installation media attributes - `node['veeam']['installer']['update_url']` and `node['veeam']['installer']['update_checksum']`.  By default, these attributes are matching their corresponding `node['veeam']['installer']['package_url']` and `node['veeam']['installer']['package_checksum']` values and the system will download the Zip every time.

| Version | ISO URL | SHA256 |
| ------------- |-------------|-------------|
| **Update 1** | [VeeamBackup&Replication_9.5.0.823_Update1.zip](https://download.veeam.com/VeeamBackup&Replication_9.5.0.823_Update1.zip) | c07bdfb3b90cc609d21ba94584ba19d8eaba16faa31f74ad80814ec9288df492 |
| **Update 2** | [VeeamBackup&Replication_9.5.0.1038.Update2.zip](http://download.veeam.com/VeeamBackup&Replication_9.5.0.1038.Update2.zip) | d800bf5414f1bde95fba5fddbd86146c75a5a2414b967404792cc32841cb4ffb |
| **Update 3** | [VeeamBackup&Replication_9.5.0.1536.Update3.zip](http://download.veeam.com/VeeamBackup&Replication_9.5.0.1536.Update3.zip) | 38ed6a30aa271989477684fdfe7b98895affc19df7e1272ee646bb50a059addc |

### Veeam Backup and Replication License file
The server must be licensed to unlock the full potential of the application.  The attribute `node['veeam']['server']['evaluation']` should be configured as `false`.  To license, choose one of the below options.

1. Save the license file on a web server to which the Veeam Backup and Replication server can access.  Set the `node['veeam']['license_url']` attribute to include the full path to the license file.
2. Encode the license file as a [Base64 string](https://www.base64encode.org/) and create a new DataBag `veeam` with an Item `license`.  Add the key license with the value as the Base64 encoded string.

```json
{
  "id": "license",
  "license": "base64_encoded_license"
}
```
## Veeam Upgrade Procedures and Details
The process to perform upgrades requires that the appropriate installation media is provided which contains the updates from Veeam.  This cookbook will initiate an upgrade if the currently installed versions are less than the desired Build version as defined by the attribute `node['veeam']['build']`.  When the installed version does not match the requested build version, the process will mount the ISO or extract the ZIP that contains the update and then perform an automatic upgrade of each service installed on the host.

### Configuring the Updates
Updates are identified by passing one of the following to the attributes for the server:
1. `node['veeam']['installer']['update_url']` attribute should contain either the full installation ISO or the update ZIP link.  The file name must include the full build name like such:
    - VeeamBackup&Replication_9.5.0.1536.Update3.iso
    - VeeamBackup&Replication_9.5.0.1536.Update3.zip
2. `node['veeam']['installer']['package_url']` attribute should contain either the full installation ISO.  The file name must include the full build name like such:
    - VeeamBackup&Replication_9.5.0.1536.Update3.iso
3. `node['veeam']['build']` attribute must be a valid and cookbook supported build version like such:
    - 9.5 (defaults to GA)
    - 9.5.0.711 (GA)
    - 9.5.0.1038 (Update2)
    - 9.5.0.1536 (Update3)

### Upgrade Process and Warnings
*Warning*
When the upgrade is performed, the installation will upgrade all components included in the server to which the update is applied.  If the upgrade requires a reboot, this process will be automatic and initiate a reboot of the server upon completion of the work.

*NOTE:*
If the automatic upgrade should be skipped then set the following attribute on the server prior to running the upgrade:
- `node['veeam']['reboot_on_upgrade']` = false

### Recipes that perform automatic upgrades
Ongoing updates are automatically handled by the following included recipes:
- standalone_complete
- proxy_server
- upgrade


## Resource/Provider

### Veeam_Prerequisites
Installs the required resoures to support Veeam applications.  Included in this resource:
- .NET Framework 4.5.2
- Microsoft SQL Server System CLR Types (x64)
- Microsoft SQL Server Management Objects (x64)
- Microsoft SQL Server (64-bit) [optional]

#### Actions:
* `:install` - Installs all of the prerequisites and optionally installs SQL Express

#### Properties:
_NOTE: properties in bold are required_
* **`version`** - Installation version.  Will determine ISO download path if `package_url` is nil
* `package_url` - Full URL to the installation media
* `package_checksum` - sha256 checksum of the installation media
* `install_sql` - Determines if SQL Express should be installed as part of adding the prerequisites.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# Install default Prerequisite tools including SQL Express
veeam_prerequisites 'Install Veeam Prerequisites' do
  version '9.0'
  install_sql true
  action :install
end
```

```ruby
# Install default Prerequisite tools but no SQL Express using a custom url
veeam_prerequisites 'Install Veeam Prerequisites' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  action :install
end
```

### Veeam_Catalog
Installs the Veeam Catalog Service

#### Actions:
* `:install` - Installs the Veeam Backup Catalog service

#### Properties:
_NOTE: properties in bold are required_

* **`version`** - Installation version.  Will determine ISO download path if `package_url` is nil
* `package_url` - Full URL to the installation media
* `package_checksum` - sha256 checksum of the installation media
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
  version '9.0'
  action :install
end
```

```ruby
# A quick install of the catalog accepting all of the defaults using a custom url
veeam_catalog 'Install Veeam Backup Catalog' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  action :install
end
```

```ruby
# Install of the catalog with a custom the service user set to a domain service account
veeam_catalog 'Install Veeam Backup Catalog' do
  version '9.0'
  vbrc_service_user 'mydomain\_srvcuser'
  vbrc_service_password 'myPassword1'
  action :install
end
```

### Veeam_Console
Installs the Veeam Backup and Replication Console

#### Actions:
* `:install` - Installs the Veeam Backup and Replication Console service

#### Properties:
_NOTE: properties in bold are required_

* **`version`** - Installation version.  Will determine ISO download path if `package_url` is nil
* `package_url` - Full URL to the installation media
* `package_checksum` - sha256 checksum of the installation media
* **`accept_eula`** - Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA.  Default = false
* `install_dir` - Sets the install directory for the Veeam Backup console service
* `keep_media` - When set to true, the downloaded ISO will not be deleted.  This is helpful if you are installing multiple services on a single node.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# A quick install of the console accepting all of the defaults
veeam_console 'Install Veeam Backup console' do
  version '9.0'
  accept_eula true
  action :install
end
```
```ruby
# A quick install of the console accepting all of the defaults using a custom url
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
  version '9.0'
  install_dir 'C:\Veeam\Console'
  accept_eula true
  action :install
end
```

### Veeam_Server
Installs the Veeam Backup and Replication Service

#### Actions:
* `:install` - Installs the Veeam Backup and Replication service

#### Properties:
_NOTE: properties in bold are required_

* **`version`** - Installation version.  Will determine ISO download path if `package_url` is nil
* `package_url` - Full URL to the installation media
* `package_checksum` - sha256 checksum of the installation media
* **`accept_eula`** - Must be set to true or the server will not install.  Since we can download the media directly, it is a good idea to enforce the EULA.  Default = false
* `install_dir` - Sets the install directory for the Veeam Backup and Replication service
* `evaluation` - Determines if the Veeam Backup and Replication server should be installed using Evaluation Mode or if a license should be attached.
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
  version '9.0'
  accept_eula true
  action :install
end
```

```ruby
# A quick install of the backup service accepting the EULA and all of the defaults using a custom url
veeam_server 'Install Veeam Backup Server' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  accept_eula true
  action :install
end
```

```ruby
# Install of the Backup and Replication service with a custom the service user set to a domain service account
veeam_server 'Install Veeam Backup Catalog' do
  version '9.0'
  accept_eula true
  vbr_service_user 'mydomain\_srvcuser'
  vbr_service_password 'myPassword1'
  action :install
end
```

### Veeam_Explorer
Installs the Veeam Backup and Replication Explorers

#### Actions:
* `:install` - Installs the Veeam Backup and Replication Explorers

#### Properties:
_NOTE: properties in bold are required_

* **`version`** - Installation version.  Will determine ISO download path if `package_url` is nil
* `package_url` - Full URL to the installation media
* `package_checksum` - sha256 checksum of the installation media
* `keep_media` - When set to true, the downloaded ISO will not be deleted.  This is helpful if you are installing multiple services on a single node.
* **`explorers`** - List of Veeam Backup Explorers to be installed.
* `package_name` - FUTURE property
* `share_path` - FUTURE property

#### Examples:
```ruby
# A quick install of the Active Directory Explorer accepting all of the defaults
veeam_explorer 'Veeam Explorer for Microsoft Active Directory' do
  version '9.0'
  explorers 'ActiveDirectory'
  action :install
end
```
```ruby
# A quick install of the SQL Server Explorer accepting all of the defaults using a custom url
veeam_explorer 'Veeam Explorer for Microsoft SQL Server' do
  package_url 'http://myartifactory/Veeam/installationmedia.iso'
  package_checksum 'sha256checksum'
  explorers 'SQL'
  action :install
end
```

### Veeam_Upgrade
Installs the Veeam Backup and Replication Update.  Requires that the host have an installation of one of the following:
- Veeam Backup & Replication Console
- Veeam Backup & Replication Server
- Veeam Backup & Replication Catalog

#### Actions:
* `:install` - Installs the Veeam Backup and Replication Upgrade

#### Properties:
_NOTE: properties in bold are required_

* `build`            - Identifies the requested build to install. Will determine Zip download path if `package_url` is nil. If not set, then will be determined based on the `package_url`
* `package_url`      - Full URL to the installation media.  Can be an ISO or Update zip
* `package_checksum` - sha256 checksum of the installation media
* `keep_media`       - When set to true, the downloaded ISO or Update Zip will not be deleted.  This is helpful if you are installing multiple services on a single node.
* `auto_reboot`      - When set to true, the system will automatically reboot if required after performing the update.
* `package_name`     - FUTURE property
* `share_path`       - FUTURE property

#### Examples:
```ruby
# Automatically upgrade to Update3 by downloading the Zip from Veeam directly and reboot upon completion
veeam_upgrade '9.5.0.1536' do
  action :install
end
```
```ruby
# Automatically upgrade to Update3 using a custom update url and skip the automatic reboot
veeam_explorer 'Veeam Upgrade' do
  build       '9.5.0.1536'
  package_url 'http://myartifactory/Veeam/installationmedia_9.5.0.1536.Update3.zip'
  package_checksum 'sha256checksum'
  auto_reboot false
  action :install
end
```

### Veeam_Proxy
Configures the host as a Proxy Server

#### Actions:
* `:add` - Registers the Windows server to VBR and Configures as a Proxy
* `:remove` - Removes the Proxy registration and unregisters the Windows Server from VBR

#### Properties:
_NOTE: properties in bold are required_

* `package_name` - FUTURE property
* `share_path` - FUTURE property

* `*hostname*` - DNS or IP Address of the server to register as the Proxy
* `*vbr_server*` - DNS or IP Address of the Veeam Backup and Replication Server
* `vbr_server_port` - Veeam Backup and Replication Server Port.  Default: 9392
* `*vbr_username*` - Username with permissions to add Servers and Proxies within Veeam Backup and Replication server
* `*vbr_password*` - Password for the user provided
* `*proxy_username*` - Username with Access to the Proxy Server.  Will generate a new set of credentials within Veeam Backup and Replication server if none exist.
* `*proxy_password*` - Password for the user provided
* `proxy_type` - Type of Proxy Server to Add.  Supported types - vmware or hyperv
* `description` - Description for the Proxy Server.  Will automatically start with "ADDED by CHEF: ".  Defaults to "ADDED by CHEF: Proxy Server"
* `max_tasks` - Specifies the number of concurrent tasks that can be assigned to the proxy simultaneously. Permitted values: 1-100. default: 2
* `transport_mode` - Specifies the transport mode used by the backup proxy.  Supported Values 'Auto','DirectStorageAccess','HotAdd','Nbd'. Default: 'Auto'


_Future Properties_
* `datastore_mode` - Specifies the mode the proxy will use to connect to datastores.  Supported Values 'Auto' or 'Manual'.  Default: 'Auto'
* `datastore` - Specifies the list of datastores to which the backup proxy has a direct SAN or NFS connection.
* `enable_failover_to_ndb` - Indicates if the backup proxy must fail over to the Network transport mode if it fails to transport data in the Direct storage access or Virtual appliance transport mode. Default: false
* `host_encryption` - Indicates if VM data must be transported over an encrypted SSL connection in the Network transport mode. Default: false


#### Examples:
```ruby
# Add a new VMware Proxy and register
veeam_proxy 'proxy01.demo.lab' do
  vbr_server      'veeam.demo.lab'
  vbr_username    'demo\\veeamuser'
  vbr_password    'mysecretpassword'
  proxy_username  'demo\\administrator'
  proxy_password  'myextrapassword'
  proxy_type      'vmware'
  action :add
end
```
```ruby
# Remove the current Veeam Proxy and Server registration
veeam_proxy 'proxy01.demo.lab' do
  vbr_server      'veeam.demo.lab'
  vbr_username    'demo\\veeamuser'
  vbr_password    'mysecretpassword'
  action :remove
end
```

## Usage
### default

This is an empty recipe and should _not_ be used

### catalog recipe

Installs and configures Veeam Backup and Replication Catalog service using the default configuration including pre-requisites

### server recipe

Installs and configures Veeam Backup and Replication Server service using the default configuration including pre-requisites and SQLExpress

### console recipe

Installs and configures Veeam Backup and Replication Console using the default configuration including pre-requisites

### server_with_catalog recipe

Installs and configures Veeam Backup and Replication Server & Catalog using the default configuration including pre-requisites and SQLExpress

### server_with_console recipe

Installs and configures Veeam Backup and Replication Server & Console using the default configuration including pre-requisites and SQLExpress.  Also installs all of the Veeam Backup Explorers

### standalone_complete recipe

Installs and configures Veeam Backup and Replication Server, Console & the Catalog service using the default configuration including pre-requisites and SQLExpress.  Also installs all of the Veeam Backup Explorers and performs an upgrade to the requested Build level.  For more information, see [Veeam Upgrade Procedures and Details](#Veeam-Upgrade-Procedures-and-Details)

### proxy recipe

Installs and configures Veeam Backup and Replication Console using the default configuration including pre-requisites and performs an upgrade to the requested Build level.  For more information, see [Veeam Upgrade Procedures and Details](#Veeam-Upgrade-Procedures-and-Details).  Also registers the Proxy Server to the Veeam Backup and Replication Server.

### proxy_remove recipe
Unregisters the Proxy Server and removes the Server registration from the Veeam Backup and Replication Server.

### upgrade recipe
Performs an upgrade of Veeam components to the requested Build level.  For more information, see [Veeam Upgrade Procedures and Details](#Veeam-Upgrade-Procedures-and-Details)

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
* `install_veeam_explorer(resource_name)`
* `add_veeam_proxy(resource_name)`
* `remove_veeam_proxy(resource_name)`
* `install_veeam_upgrade(resource_name)`

### Veeam::Helper
_Note:  A helper to handle common and repeated functions_

#### check_os_version
Determines if the current node meets the OS type and requirements. If False, then raise an Argument Errors depending if the node['platform_version'] or node['kernel']['machine'] are wrong.
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
check_os_version(node)
```

#### find_package_url(version)
Uses the supplied version identifier to return the stored URL location of the installation media.  This method calls the package_list method to identify the correct information
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
package_url = find_package_url(new_resource.version)
```

#### find_package_checksum(version)
Uses the supplied version identifier to return the stored checksum for the installation media.  This method calls the package_list method to identify the correct information
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
package_checksum = find_package_checksum(new_resource.version)
```

#### find_update_url(version)
Uses the supplied version identifier to return the stored URL location of the update media.  This method calls the update_list method to identify the correct information
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
update_url = find_update_url(new_resource.version)
```

#### find_update_checksum(version)
Uses the supplied version identifier to return the stored checksum for the update media.  This method calls the update_list method to identify the correct information
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
update_checksum = find_update_checksum(new_resource.version)
```

#### prerequisites_list
Returns an array of version specific prerequisite package versions
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
prerequisites_list = prerequisites_list(new_resource.version)
```

#### explorers_list
Returns an array of version specific explorer package versions
```
# usage in a custom_resource
::Chef::Provider.send(:include, Veeam::Helper)
explorers_list = explorers_list(new_resource.version)
```

#### find_current_dotnet
Returns the current installed version of .NET

#### validate_powershell_out(script, timeout: nil)
Sends command data to the powershell_out method and validates the output contains no errors

#### find_current_veeam_solutions(package_name)
Determine the install location based on the supplied Package Name.  Expected values are:
- Veeam Backup & Replication Console
- Veeam Backup & Replication Server
- Veeam Backup & Replication Catalog

#### find_current_veeam_version(package_name)
Determine the build version for the installed packages.  Expected values are:
- Veeam Backup & Replication Console
- Veeam Backup & Replication Server
- Veeam Backup & Replication Catalog

#### iso_installer(downloaded_file_name, new_resource)
Helper method to download and mount the ISO media

#### extract_installer(downloaded_file_name, new_resource)
Helper method to download and extract the Update Zip files.  The files will be save in the default :file_cache location in a subdirectory called `Veeam/<filename>/Updates`

#### unmount_installer(downloaded_file_name)
Helper method to find and unmount the ISO media

#### get_media_installer_location(downloaded_file_name)
Helper method to determine the drive letter of the mounted ISO media

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
| **rake integration:kitchen:catalog-windows-2016** | Run catalog-windows-2016 test instance |
| **rake integration:kitchen:console-windows-2012r2** | Run console-windows-2012r2 test instance |
| **rake integration:kitchen:console-windows-2016** | Run console-windows-2016 test instance |
| **rake integration:kitchen:server-windows-2012r2** | Run server-windows-2012r2 test instance |
| **rake integration:kitchen:server-windows-2016** | Run server-windows-2016 test instance |
| **rake integration:kitchen:server-with-catalog-windows-2012r2** | Run server-with-catalog-windows-2012r2 test instance |
| **rake integration:kitchen:server-with-catalog-windows-2016** | Run server-with-catalog-windows-2016 test instance |
| **rake integration:kitchen:server-with-console-windows-2012r2** | Run server-with-console-windows-2012r2 test instance |
| **rake integration:kitchen:server-with-console-windows-2016** | Run server-with-console-windows-2016 test instance |
| **rake integration:kitchen:standalone-complete-windows-2012r2** | Run standalone-complete-windows-2012r2 test instance |
| **rake integration:kitchen:standalone-complete-windows-2016** | Run standalone-complete-windows-2016 test instance |
| **rake integration:kitchen:proxy-server-2012r2** | Run proxy-server-2012r2 test instance |
| **rake integration:kitchen:proxy-server-2016** | Run proxy-server-2016 test instance |
| **rake integration:kitchen:proxy-remove-2012r2** | Run proxy-remove-2012r2 test instance |
| **rake integration:kitchen:proxy-remove-2016** | Run proxy-remove-2016 test instance |
| **rake integration:kitchen:upgrade-2012r2** | Run upgrade-2012r2 test instance |
| **rake integration:kitchen:upgrade-2016** | Run upgrade-2016 test instance |
| **rake maintainers:generate** | Generate MarkDown version of MAINTAINERS file |

### Chefspec and Test-Kitchen

1. `bundle install`: Installs and pulls all ruby gems dependencies from the Gemfile.

2. `berks install`: Installs all cookbook dependencies based on the [Berksfile](Berksfile) and the [metadata.rb](metadata.rb)

3. `rake`: This will run all of the local tests - syntax, lint, unit, and maintainers file.
4. `rake integration`: This will run all of the kitchen tests

### Compliance Profile
Included in this cookbook is a set of Inspec profile tests used for the Windows 2012 and greater Test-Kitchen.  These profiles can also be loaded into Chef Compliance to ensure on-going validation.  The Control files are located at `test/inspec/suite_name`

- test/inspec/9.0.0.902/catalog
- test/inspec/9.0.0.902/console
- test/inspec/9.0.0.902/server
- test/inspec/9.5.0.711/catalog
- test/inspec/9.5.0.711/console
- test/inspec/9.5.0.711/server

## Contribute
 - Fork it
 - Create your feature branch (git checkout -b my-new-feature)
 - Commit your changes (git commit -am 'Add some feature')
 - Push to the branch (git push origin my-new-feature)
 - Create new Pull Request

## License and Author

_Note: This cookbook is not officially supported by or released by Veeam Software, Inc._

- Author:: Exosphere Data, LLC ([chef@exospheredata.com](mailto:chef@exospheredata.com))

```text
Copyright 2017 Exosphere Data, LLC
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
except in compliance with the License. You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.
```
