control 'catalog-feature-installed' do
  impact 1.0
  title 'Verify Veeam Backup Catalog installed'
  desc 'Check if the Veeam Backup Catalog instance is installed and configured'

  describe port(9393) do
    it { should be_listening }
  end

  describe service('VeeamCatalogSvc') do
    it { should be_running }
    its('startmode') { should match('Auto') }
  end

  describe package('Veeam Backup Catalog') do
    it { should be_installed }
    its('version') { should eq '9.5.0.711' }
  end
end
