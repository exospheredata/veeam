control 'Server-feature-installed' do
  impact 1.0
  title 'Verify Veeam Backup Server installed'
  desc 'Check if the Veeam Backup Server instance is installed and configured'

  describe port(9392) do
    it { should be_listening }
  end

  describe service('VeeamBackupSvc') do
    it { should be_running }
    its('startmode') { should match('Auto') }
  end

  describe package('Veeam Backup & Replication Server') do
    it { should be_installed }
    its('version') { should eq '9.5.0.711' }
  end
end
