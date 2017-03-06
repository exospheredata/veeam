control 'console-feature-installed' do
  impact 1.0
  title 'Verify Veeam Backup and Recovery Console installed'
  desc 'Check if the Veeam Backup and Recovery Console instance is installed and configured'

  describe port(6170) do
    it { should be_listening }
  end

  describe package('Veeam Backup & Replication Console') do
    it { should be_installed }
    its('version') { should eq '9.5.0.711' }
  end
end
