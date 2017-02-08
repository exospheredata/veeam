#
# Cookbook Name:: veeam
# Spec:: catalog
#
# Copyright (c) 2016 Exosphere Data LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::catalog' do
  before do
    mock_windows_system_framework # Windows Framework Helper from 'spec/windows_helper.rb'
    stub_command('sc.exe query W3SVC').and_return 1
    stub_command(/Get-DiskImage/).and_return(false)
  end
  context 'Install prequisite components' do
    platforms = {
      'windows' => {
        'versions' => %w(2008R2 2012 2012R2)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          before do
            Fauxhai.mock(platform: platform, version: version)
            allow(Chef::Config).to receive(:file_cache_path)
              .and_return('...')
          end

          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version,
                                     file_cache_path: '/tmp/cache', step_into: ['veeam_catalog']) do |node|
              # TODO: Likely need to add some objects for node testing
            end.converge(described_recipe)
          end

          it 'converges successfully' do
            expect(chef_run).to install_veeam_catalog('Install Veeam Backup Catalog')
            expect { chef_run }.not_to raise_error
          end
          it 'Step into LWRP - veeam_catalog' do
            package_save_dir = win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package'))
            downloaded_file_name = win_friendly_path(::File.join(package_save_dir, 'VeeamBackup&Replication_9.0.0.902.iso'))
            installer_location = downloaded_file_name.gsub('.iso', '')

            expect(chef_run).to create_directory(package_save_dir)
            expect(chef_run).to create_remote_file(downloaded_file_name)
            expect(chef_run).to run_powershell_script('Load Veeam media')
            expect(chef_run).to run_ruby_block('Install the Backup Catalog application')

            # Validate the do nothings
            downloaded_file = chef_run.file(downloaded_file_name)
            expect(downloaded_file).to do_nothing

            install_dir = chef_run.directory(installer_location)
            expect(install_dir).to do_nothing
          end
        end
      end
    end
  end
  context 'Test installation' do
    platforms = {
      'windows' => {
        'versions' => %w(2003R2) # Unable to test plain Win2008 since Fauxhai doesn't have a template for 2008
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
            expect { chef_run }.to raise_error('This recipe requires a Windows 2008R2 or higher host!')
          end
        end
      end
    end
  end
end
