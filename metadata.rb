name 'veeam'
maintainer 'Exosphere Data, LLC'
maintainer_email 'chef@exospheredata.com'
license 'Apache-2.0'
description 'Installs/Configures Veeam Backup and Recovery'
<<<<<<< HEAD
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '3.0.1'
chef_version '>= 12.5' if respond_to?(:chef_version)
=======
version '4.0.0'
chef_version '>= 13.0'
>>>>>>> Version 4.0.0 - Support for v10.0

supports 'windows'

depends 'windows'

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Issues` link
issues_url 'https://github.com/exospheredata/veeam/issues'

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Source` link
source_url 'https://github.com/exospheredata/veeam'
