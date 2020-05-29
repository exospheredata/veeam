#
# Cookbook:: veeam
# Spec:: proxy_remove
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2020, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::proxy_remove' do
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
            node.override['veeam']['proxy']['vbr_server']   = 'veeam'
            node.override['veeam']['proxy']['vbr_username'] = 'admin'
            node.override['veeam']['proxy']['vbr_password'] = 'password'
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
            ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache', step_into: ['veeam_proxy'])
          end
          let(:node) { runner.node }
          let(:chef_run) { runner.converge(described_recipe) }
          let(:package_save_dir) { win_clean_path(::File.join(Chef::Config[:file_cache_path], 'package')) }
          let(:downloaded_file_name) { win_clean_path(::File.join(package_save_dir, 'VeeamBackup_Replication_9.5.0.711.iso')) }

          it 'converges successfully' do
            stubs_for_provider('veeam_proxy[Fauxhai]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Check if Proxy is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Windows Host from VBR/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Veeam Proxy from VBR/).and_return(true_shell)
            end
            # expect { chef_run }.not_to raise_error
            expect(chef_run).to remove_veeam_proxy(node['hostname'])
          end
          it 'Step into LWRP - veeam_proxy' do
            stubs_for_provider('veeam_proxy[Fauxhai]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Check if Proxy is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Windows Host from VBR/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Veeam Proxy from VBR/).and_return(true_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to run_powershell_script('Remove Veeam Proxy')
            expect(chef_run).to run_powershell_script('Remove Windows Server')
          end
          it 'Should not unregister the host if not found in Veeam' do
            stubs_for_provider('veeam_proxy[Fauxhai]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(false_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Check if Proxy is registered/).and_return(false_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to_not run_powershell_script('Remove Veeam Proxy')
            expect(chef_run).to_not run_powershell_script('Remove Windows Server')
          end
          it 'Should unregister the host but skip the Proxy if not configured' do
            stubs_for_provider('veeam_proxy[Fauxhai]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Check if Proxy is registered/).and_return(false_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to_not run_powershell_script('Remove Veeam Proxy')
            expect(chef_run).to run_powershell_script('Remove Windows Server')
          end
          it 'Should remove the Proxy but skip Host if not configured' do
            stubs_for_provider('veeam_proxy[Fauxhai]') do |provider|
              allow(provider).to receive(:shell_out_compacted).with(/Check if Host is registered/).and_return(false_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Check if Proxy is registered/).and_return(true_shell)
              allow(provider).to receive(:shell_out_compacted).with(/Unregister Veeam Proxy from VBR/).and_return(true_shell)
            end
            expect { chef_run }.not_to raise_error
            expect(chef_run).to run_powershell_script('Remove Veeam Proxy')
            expect(chef_run).to_not run_powershell_script('Remove Windows Server')
          end
          it 'Should raise an exception if the Veeam Console is not installed' do
            allow_any_instance_of(Chef::Provider)
              .to receive(:is_package_installed?)
              .and_return(false)
            expect { chef_run }.to raise_error(ArgumentError, /This resource requires that the Veeam Backup & Replication Console be installed on this host/)
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
