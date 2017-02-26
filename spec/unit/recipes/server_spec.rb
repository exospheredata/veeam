#
# Cookbook Name:: veeam
# Spec:: server
#
# Copyright (c) 2016 Exosphere Data LLC, All Rights Reserved.

require 'spec_helper'

describe 'veeam::server' do
  before do
    mock_windows_system_framework # Windows Framework Helper from 'spec/windows_helper.rb'
    stub_command('sc.exe query W3SVC').and_return 1
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
            ChefSpec::SoloRunner.new(platform: platform, version: version) do |node|
              # TODO: Likely need to add some objects for node testing
            end.converge(described_recipe)
          end

          it 'converges successfully' do
            expect(chef_run).to install_veeam_prerequisites('Install Veeam Prerequisites')
            expect(chef_run).to install_veeam_server('Install Veeam Backup Server')
            expect { chef_run }.not_to raise_error
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
