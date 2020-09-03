# Change log information for Veeam Cookbook

## Version 4.1.0
2020-09-02

- UPDATE: SQL instance names are now flexible trough an attribute.

## Version 4.0.3
2020-08-14

UPDATE: Library::Helper to include 10.0.1.4854 (10.0a) installation
UPDATE: Resource::Console to correct product version to look at individual solution
UPDATE: Resource::Catalog to correct product version to look at individual solution

## Version 4.0.2
2020-08-12

Updated - Changed SQL authentication mode from "Mixed" to "Windows"
Updated the upgrade process to handle incremental upgrades and setting the correct build_version based on the package_url

## Version 4.0.1
2020-08-6

Added support for Veeam 9.5.4b

## Version 4.0.0
2020-07-15

Major update to include support for Veeam 10.0.0 including changes to the method for installation of SQL Express and supported .NET Framework

### Included:

- UPDATE: Libraries::Helper to support v10.0+
- UPDATE: Resources::Prerequisites to handle new library methods to look up dotnet and sqlexpress versions
- UPDATE: Templates::sql_build_script to pass sqlexpress media path from helper
- ADD:    Inspec::10.0.0.4461 tests
- UPDATE: Spec::lwrps/veeam_prerequisites_spec to support Chef 13+
- UPDATE: Resources::Host to add script marker comments for stubs
- UPDATE: Resources::Proxy to add script marker comments for stubs
- UPDATE: Unit tests with new shell_out_compacted method for command stubbing
- UPDATE: all files to support updated rubcop and foodcritic standards
- UPDATE: Helpers::ExtractInstaller to use archive_file resource
- UPDATE: CHANGELOG.md
- UPDATE: README.md
- BUMP:   Metadata 4.0.0

## Version 3.0.2
2020-07-24

Minor fix update for SQL Express installation on domain joined computer.

## Version 3.0.1
2020-07-14

Minor fix update to include `delay_min 1` to all reboot resources to cover a chef bug that lets some test-kitchen environments crash.

## Version 3.0.0
2019-01-22

Major update to include support for Veeam 9.5.4 including changes to the method for installation and upgrades

### Included:

- UPDATE: Kitchen.yml typo
- UPDATE: Libraries::Helper to enhance prerequisites versions
- UPDATE: Libraries::Helper to include support to ignore_errors in validate_cmd method when called from method find_current_veeam_version
- UPDATE: Libraries::Helper to include version information for explorers and win_clean_path helper
- UPDATE: Libraries::Helper to include links for 9.5.4

- UPDATE: Recipes::Catalog to include calling veeam_upgrade by default
- UPDATE: Recipes::Console to include veaam_upgrade
- UPDATE: Recipes::HostMgmt to support 9.5.4
- ADD: Recipes::Prerequisites
- UPDATE: Recipes::ProxyServer to support 9.5.4
- UPDATE: Recipes::Server to support 9.5.4
- UPDATE: Recipes::ServerWithConsole to include upgrades and build version handling
- UPDATE: Recipes::StandaloneComplete to support 9.5.4

- UPDATE: Resources to use win_clean_path instead of win_friendly_path from Windows Cookbook
- UPDATE: Resources::Catalog to handle installation of 9.5.4 media and upgrades of the current version from 9.5.0 to 9.5.4 when version is selected
- UPDATE: Resources::Console to support upgrading and installing 9.5.4
- UPDATE: Resources::Explorer to support 9.5.4 version upgrades
- UPDATE: Resources::Prerequisites to support new version of SQL Express installation based on the build_version
- UPDATE: Resources::Server to enable support for upgrading the version to 9.5.4
- UPDATE: Resources::Upgrade to initiate an upgrade when the Veeam Backup Catalog version does not match the requested build version

- UPDATE: Templates::SqlBuildScript to handle installation of SQL Express 2016 when performing a new installation of 9.5 Update 4
- ADD: Test::Inspec/9.5.4

- UPDATE: README
- BUMP: Metadata to Version 3.0.0

## Version 2.1.1
2018-08-25

Minor fix update to include `auto_reboot` override to the Recipe::Proxy and Recipe::HostMgmt

## Version 2.1
2018-08-24

Minor update to include default links for downloading Update 3a.  Also added a new resource and recipe to allow for automatic adding of a host to the Server Inventory of Veeam Backup and Replication.

### Included:
- Updated Helpers to include support for Veeam 9.5.0.1922 (Update 3a)
- Add resource to control adding new Hosts into Veeam Inventory.

### Information on new resources:

* **VeeamHost** - Registers the provided server as the selected type by connecting to the Veeam Backup and Replication server via the Veeam PowerShell toolkit.  This resource will add a Veeam credential object if one does not exist and then register the server.

## Version 2.0
2018-05-04

Major update to the Veeam cookbook with full testing against Chef client 14.0.202.  This update includes two new custom resources - VeeamProxy and VeeamUpgrade. Along with the new resources, a complete refactor of existing resources was completed to consolidate the helper methods into a single library.

### Included:
- Veeam Backup and Replication ProxyServer deployments
- Support for automatic Veeam Backup and Replication component Updates
- Refactor of existing Custom Resources and Helper Library

### Information on new resources:

* **VeeamProxy** - Configures a Windows server as either a VMware or HyperV Backup Proxy by connecting to the Veeam Backup and Replication server via the Veeam PowerShell toolkit.  This resource will add a Veeam credential object if one does not exist and then register the server as a Proxy Type.
* **VeeamUpgrade** - The process to perform upgrades requires that the appropriate installation media is provided which contains the updates from Veeam.  This cookbook will initiate an upgrade if the currently installed versions are less than the desired Build version as defined by the attribute `node['veeam']['build']`.  When the installed version does not match the requested build version, the process will mount the ISO or extract the ZIP that contains the update and then perform an automatic upgrade of each service installed on the host.

### Major Updates:
- Veeam::Helper refactor
- SQL Express installation via Windows Scheduled task (resolves issues with remote builds on domain joined servers)


This cookbook is not officially supported by Veeam Software

## Version 1.0
2017-11-05

Initial release of the Veeam Cookbook including support for the new provisioning

### Included:
- Veeam Backup and Replication Server deployments
- Veeam Backup and Replication Catalog deployments
- Veeam Backup and Replication Console deployments
- Veeam Backup and Replication Prerequisite deployments
- Custom Resources and Helper Library


### Information on new resources:

* **VeeamPrerequisites** - Deploys all Veeam Prerequisite packages including SQL Tools, .NET 4.5, and SQL Express.
* **VeeamConsole** - Installs the Veeam Backup and Replication Console
* **VeeamCatalog** - Installs the Veeam Backup and Replication Catalog
* **VeeamServer** - Installs the Veeam Backup and Replication Server
* **VeeamExplorers** - Installs the Veeam Backup and Replication Explorers based on those available in the Installation Media.

This cookbook is not officially supported by Veeam Software
