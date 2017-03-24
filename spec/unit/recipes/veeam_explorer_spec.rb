#
# Cookbook Name:: veeam
# Spec:: explorer
#
# Copyright (c) 2016 Exosphere Data LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::server_with_console' do
  before do
    mock_windows_system_framework # Windows Framework Helper from 'spec/windows_helper.rb'
    stub_command('sc.exe query W3SVC').and_return 1
    stub_command(/Get-DiskImage/).and_return(false)
    stub_data_bag_item('veeam', 'license').and_return(nil)
  end
  context 'Test valid installation' do
    platforms = {
      'windows' => {
        'versions' => %w(2008R2) #  2012 2012R2)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          context 'successfully' do
            let(:shellout) do
            end
            before do
              Fauxhai.mock(platform: platform, version: version)
              allow(Chef::Config).to receive(:file_cache_path)
                .and_return('...')
              # Need to set a valid .NET Framework version
              allow_any_instance_of(Chef::DSL::RegistryHelper)
                .to receive(:registry_get_values)
                .and_return([{}, {}, {}, {}, {}, {}, { name: 'Release', data: 379893 }])
              node.normal['veeam']['server']['accept_eula'] = true
              node.normal['veeam']['server']['explorers'] = %w(ActiveDirectory Exchange)
              shellout = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil)
              allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
              allow(shellout).to receive(:live_stream=).and_return(nil)
              allow(shellout).to receive(:stdout).and_return('D')
              allow(shellout).to receive(:stderr).and_return(nil)
            end

            let(:runner) do
              ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache', step_into: ['veeam_explorer'])
            end
            let(:node) { runner.node }
            let(:chef_run) { runner.converge(described_recipe) }
            let(:package_save_dir) { win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package')) }
            let(:downloaded_file_name) { win_friendly_path(::File.join(package_save_dir, 'VeeamBackup&Replication_9.5.0.711.iso')) }

            it 'converges successfully' do
              expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
              expect(chef_run).to install_veeam_console('Install Veeam Backup Console')
              expect(chef_run).to install_veeam_server('Install Veeam Backup Server')
              expect(chef_run).to install_veeam_explorer('Install Veeam Backup Explorers')
              expect { chef_run }.not_to raise_error
            end
            it 'Step into LWRP - veeam_explorer' do
              expect(chef_run).to create_directory(package_save_dir)
              expect(chef_run).to create_remote_file(downloaded_file_name)
              expect(chef_run).to run_powershell_script('Load Veeam media')
              expect(chef_run).to run_ruby_block('Install Veeam Explorers')
              expect(chef_run).to delete_file(downloaded_file_name)
            end
            it 'should install explorers if defined' do
              expect { chef_run }.not_to raise_error
            end
            it 'should unmount the media' do
              stub_command(/Get-DiskImage/).and_return(true)
              expect(chef_run).to run_powershell_script('Dismount Veeam media')
            end
            it 'should not remove the media if keep_media is True' do
              node.override['veeam']['server']['keep_media'] = true
              expect(chef_run).not_to delete_file(downloaded_file_name)
            end
          end
        end
      end
    end
  end
  # context 'Test installation' do
  #   platforms = {
  #     'windows' => {
  #       'versions' => %w(2003R2) # Unable to test plain Win2008 since Fauxhai doesn't have a template for 2008
  #     }
  #   }
  #   platforms.each do |platform, components|
  #     components['versions'].each do |version|
  #       context "On #{platform} #{version}" do
  #         before do
  #           Fauxhai.mock(platform: platform, version: version)
  #         end

  #         let(:chef_run) do
  #           ChefSpec::SoloRunner.new(platform: platform, version: version).converge(described_recipe)
  #         end
  #         it 'raises an exception' do
  #           expect { chef_run }.to raise_error('This recipe requires a Windows 2008R2 or higher host!')
  #         end
  #       end
  #     end
  #   end
  # end
end
