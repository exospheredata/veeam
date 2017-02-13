name 'veeam'
maintainer 'Exosphere Data LLC'
maintainer_email 'chef@exospheredata.com'
license 'all_rights'
description 'Installs/Configures Veeam Backup and Recovery'
long_description 'Installs/Configures Veeam Backup and Recovery'
version '0.1.0'

supports 'windows'

depends 'windows', '2.0.2'
depends 'ms_dotnet', '3.1.0'

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Issues` link
# issues_url 'https://github.com/<insert_org_here>/veeam/issues' if respond_to?(:issues_url)

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Source` link
# source_url 'https://github.com/<insert_org_here>/veeam' if respond_to?(:source_url)
