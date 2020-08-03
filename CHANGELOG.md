# Change log information for Veeam Cookbook

## Version 3.0.2
2020-07-24

Minor fix update for SQL Express installation on domain joined computer.

## Version 3.0.1
2020-07-14

Minor fix update to include `delay_min 1` to all reboot resources to cover a chef bug that lets some test-kitchen environments crash.

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
