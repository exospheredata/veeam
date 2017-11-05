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
  context 'Install Veeam Backup and Recovery Catalog' do
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
            # Need to set a valid .NET Framework version
            allow_any_instance_of(Chef::DSL::RegistryHelper)
              .to receive(:registry_get_values)
              .and_return([{}, {}, {}, {}, {}, {}, { name: 'Release', data: 379893 }])
          end

          let(:runner) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache', step_into: ['veeam_catalog'])
          end
          let(:node) { runner.node }
          let(:chef_run) { runner.converge(described_recipe) }
          let(:package_save_dir) { win_friendly_path(::File.join(Chef::Config[:file_cache_path], 'package')) }
          let(:downloaded_file_name) { win_friendly_path(::File.join(package_save_dir, 'VeeamBackup&Replication_9.5.0.711.iso')) }

          it 'converges successfully' do
            expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
            expect(chef_run).to install_veeam_catalog('Install Veeam Backup Catalog')
            expect { chef_run }.not_to raise_error
          end
          it 'Step into LWRP - veeam_catalog' do
            expect(chef_run).to create_directory(package_save_dir)
            expect(chef_run).to create_remote_file(downloaded_file_name)
            expect(chef_run).to run_powershell_script('Load Veeam media')
            expect(chef_run).to run_ruby_block('Install the Backup Catalog application')
            expect(chef_run).to delete_file(downloaded_file_name)
          end
          it 'should unmount the media' do
            stub_command(/Get-DiskImage/).and_return(true)
            expect(chef_run).to run_powershell_script('Dismount Veeam media')
          end
          it 'should not remove the media if keep_media is True' do
            node.override['veeam']['catalog']['keep_media'] = true
            expect(chef_run).not_to delete_file(downloaded_file_name)
          end
          it 'returns an Argument error when no password supplied' do
            node.override['veeam']['catalog']['vbrc_service_user'] = 'user1'
            expect { chef_run }.to raise_error(ArgumentError, /The VBRC service password must be set if a username is supplied/)
          end
          it 'returns an Argument error when invalid Veeam version supplied' do
            node.override['veeam']['version'] = '1.0'
            expect { chef_run }.to raise_error(ArgumentError, /You must provide a package URL or choose a valid version/)
          end
          it 'returns an Argument error when invalid .NET Framework' do
            allow_any_instance_of(Chef::DSL::RegistryHelper)
              .to receive(:registry_get_values)
              .and_return(nil)
            expect { chef_run }.to raise_error(RuntimeError, /The Veeam Backup and Recovery Server requires that Microsoft .NET Framework 4.5.2 or higher/)
          end
          it 'returns NO error when username and password supplied' do
            node.override['veeam']['catalog']['vbrc_service_user'] = 'user1'
            node.override['veeam']['catalog']['vbrc_service_password'] = 'password1'
            expect { chef_run }.not_to raise_error
          end
          it 'returns NO error when install_dir supplied' do
            node.override['veeam']['catalog']['install_dir'] = 'C:\\Veeam\\BackupCatalog'
            expect { chef_run }.not_to raise_error
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
