#
# Cookbook:: veeam
# Spec:: host
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2020, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::host_mgmt' do
  before do
    mock_windows_system_framework # Windows Framework Helper from 'spec/windows_helper.rb'
    stub_command('sc.exe query W3SVC').and_return 1
    stub_command(/Get-DiskImage/).and_return(false)
    allow_any_instance_of(Chef::DSL::RegistryHelper)
      .to receive(:registry_get_values)
      .and_return([{}, {}, {}, {}, {}, {}, { name: 'Release', data: 379893 }])
    allow_any_instance_of(Chef::Provider)
      .to receive(:is_package_installed?)
      .and_return(true)
  end
  context 'Install Veeam Backup and Recovery Console' do
    platforms = {
      'windows' => {
        'versions' => %w(2012 2012R2 2016)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          before do
            Fauxhai.mock(platform: platform, version: version)
            allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
            node.override['veeam']['host']['vbr_server']   = 'veeam'
            node.override['veeam']['host']['vbr_username'] = 'admin'
            node.override['veeam']['host']['vbr_password'] = 'password'
            node.override['veeam']['host']['host_username'] = 'admin'
            node.override['veeam']['host']['host_password'] = 'password'
            node.override['veeam']['build'] = '9.5.0.1536'
            node.override['veeam']['host']['server'] = 'vc1'
            node.override['veeam']['host']['type']   = 'vmware'
            node.override['veeam']['host']['action'] = 'add'
          end
          let(:shellout) do
            # Creating a double allows us to stub out the response from Mixlib::ShellOut
            double(run_command: nil, error!: nil, stdout: '', stderr: '', exitstatus: 0, live_stream: '')
          end
          let(:false_shell) do
            # We need to have a seperate double that we can use rather than trying to reuse the same one.
            # This prevents odd failures when calling two or more stubs.
            double(run_command: nil, error!: nil, stdout: 'False', stderr: '', exitstatus: 0, live_stream: '')
          end
          let(:true_shell) do
            # We need to have a seperate double that we can use rather than trying to reuse the same one.
            # This prevents odd failures when calling two or more stubs.
            double(run_command: nil, error!: nil, stdout: 'True', stderr: '', exitstatus: 0, live_stream: '')
          end
          let(:environment_var) do
            # When declaring a :new Mixlib::ShellOut, we need to pass this environment hash
            { environment: { 'LC_ALL' => 'en_US.UTF-8', 'LANGUAGE' => 'en_US.UTF-8', 'LANG' => 'en_US.UTF-8', 'PATH' => /.+/ } }
          end

          let(:runner) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache', step_into: ['veeam_host'])
          end
          let(:node) { runner.node }
          let(:chef_run) { runner.converge(described_recipe) }
          let(:package_save_dir) { win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package')) }
          let(:downloaded_file_name) { win_friendly_path(::File.join(package_save_dir, 'VeeamBackup_Replication_10.0.0.4461.iso')) }

          it 'converges successfully' do
            allow(Mixlib::ShellOut).to receive(:new).with(/Check if Host is registered/, environment_var).and_return(false_shell)
            stubs_for_provider('veeam_host[vc1]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(false_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
            expect(chef_run).to install_veeam_console('Install Veeam Backup console')
            expect(chef_run).to install_veeam_upgrade('9.5.0.1536')
            expect(chef_run).to add_veeam_host(node['veeam']['host']['server'])
          end
          it 'Step into LWRP - veeam_host' do
            stubs_for_provider('veeam_host[vc1]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(false_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Register Host to VBR/).and_return(true_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to run_powershell_script('Register Host Server')
            expect(chef_run).to_not run_powershell_script('Remove Host Server')
          end
          it 'Should not register the host if already done' do
            allow(Mixlib::ShellOut).to receive(:new).with(/Check if Host is registered/, environment_var).and_return(true_shell)
            stubs_for_provider('veeam_host[vc1]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(true_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to_not run_powershell_script('Register Host Server')
            expect(chef_run).to_not run_powershell_script('Remove Host Server')
          end
          it 'Should raise an exception if the Veeam Console is not installed' do
            allow_any_instance_of(Chef::Provider)
              .to receive(:is_package_installed?)
              .and_return(false)
            expect { chef_run }.to raise_error(ArgumentError, /This resource requires that the Veeam Backup & Replication Console be installed on this host/)
          end
          it 'Should remove Host Server if action set to :remove' do
            node.override['veeam']['host']['action'] = 'remove'
            stubs_for_provider('veeam_host[vc1]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Host to VBR/).and_return(true_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to remove_veeam_host(node['veeam']['host']['server'])
            expect(chef_run).to run_powershell_script('Remove Host Server')
          end
          it 'Should raise an error if action invalid' do
            node.override['veeam']['host']['action'] = 'delete'
            expect { chef_run }.to raise_error(ArgumentError, /Invalid value assigned to attribute \(node\['veeam'\]\['host'\]\['action'\]\): #{node['veeam']['host']['action']}/)
          end
        end
      end
    end
  end
  context 'Does not install' do
    platforms = {
      'windows' => {
        'versions' => %w(2008R2) # Unable to test plain Win2008 since Fauxhai doesn't have a template for 2008
      },
      'ubuntu' => {
        'versions' => %w(16.04)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          before do
            Fauxhai.mock(platform: platform, version: version)
          end

          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version).converge(described_recipe)
          end
          it 'raises an exception' do
            expect { chef_run }.to raise_error(ArgumentError, 'This recipe requires a Windows 2012 or higher host!')
          end
        end
      end
    end
  end
end
