#
# Cookbook:: veeam
# Spec:: host_mgmt_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2018, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::host_mgmt' do
  before do
    mock_windows_system_framework # Windows Framework Helper from 'spec/windows_helper.rb'
    stub_command('sc.exe query W3SVC').and_return 1
  end
  context 'Run recipe' do
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
            node.normal['veeam']['host']['vbr_server']   = 'veeam'
            node.normal['veeam']['host']['vbr_username'] = 'admin'
            node.normal['veeam']['host']['vbr_password'] = 'password'
            node.normal['veeam']['host']['host_username'] = 'admin'
            node.normal['veeam']['host']['host_password'] = 'password'
            node.normal['veeam']['build'] = '9.5.0.1536'
            node.normal['veeam']['host']['server'] = 'vc1'
            node.normal['veeam']['host']['type']   = 'vmware'
            node.normal['veeam']['host']['action'] = nil
          end
          let(:runner) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache')
          end
          let(:node) { runner.node }
          let(:chef_run) { runner.converge(described_recipe) }

          it 'converges successfully' do
            expect { chef_run }.not_to raise_error
            expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
            expect(chef_run).to install_veeam_console('Install Veeam Backup console')
            expect(chef_run).to install_veeam_upgrade('9.5.0.1536')
            expect(chef_run).to add_veeam_host(node['veeam']['host']['server'])
          end

          it 'removes the Veeam Host Server' do
            node.normal['veeam']['host']['action'] = 'remove'
            expect { chef_run }.not_to raise_error
            expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
            expect(chef_run).to install_veeam_console('Install Veeam Backup console')
            expect(chef_run).to install_veeam_upgrade('9.5.0.1536')
            expect(chef_run).to remove_veeam_host(node['veeam']['host']['server'])
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
