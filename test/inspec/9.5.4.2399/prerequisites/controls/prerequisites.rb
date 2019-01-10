control 'prerequisites-feature-installed' do
  impact 1.0
  title 'Verify Veeam Prerequisites installed'
  desc 'Check if the Veeam Prerequisites are installed and configured'

  describe package('Microsoft System CLR Types for SQL Server 2014') do
    it { should be_installed }
    its('version') { should eq '12.0.2402.11' }
  end

  describe package('Microsoft SQL Server 2014 Management Objects  (x64)') do
    it { should be_installed }
    its('version') { should eq '12.0.2000.8' }
  end

  describe package('SQL Server 2016 Database Engine Services') do
    it { should be_installed }
    its('version') { should eq '13.1.4001.0' }
  end
end
