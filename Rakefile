#!/usr/bin/env rake

require_relative 'tasks/maintainers'

# Style tests. cookstyle (rubocop) and Foodcritic
namespace :style do
  begin
    require 'cookstyle'
    require 'rubocop/rake_task'

    desc 'Run Ruby style checks'
    RuboCop::RakeTask.new(:ruby)
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting style:ruby" unless ENV['CI']
  end

  begin
    require 'foodcritic'

    desc 'Run Chef style checks'
    FoodCritic::Rake::LintTask.new(:chef) do |t|
      t.options = {
        fail_tags: ['any'],
        progress: true
      }
    end
  rescue LoadError
    puts ">>> Gem load error: #{e}, omitting style:chef" unless ENV['CI']
  end
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

# ChefSpec
begin
  require 'rspec/core/rake_task'

  desc 'Run ChefSpec examples'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.rspec_opts = [].tap do |a|
      a.push('--color')
      a.push('--format progress')
    end.join(' ')
  end
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting unit" unless ENV['CI']
end

# Integration tests. Kitchen.ci
namespace :integration do
  begin
    require 'kitchen/rake_tasks'

    desc 'Run kitchen integration tests'
    Kitchen::RakeTasks.new
  rescue StandardError => e
    puts ">>> Kitchen error: #{e}, omitting #{task.name}" unless ENV['CI']
  end
end
desc 'Run all kitchen suites'
task integration: ['integration:kitchen:all']

# TODO: Enable publishing to the Supermarket
# namespace :supermarket do
#   begin
#     require 'stove/rake_task'

#     desc 'Publish cookbook to Supermarket with Stove'
#     Stove::RakeTask.new
#   rescue LoadError => e
#     puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV['CI']
#   end
# end

# Default
task default: %w(style unit)

desc 'Run Local Development tests: Style, Foodcritic, Maintainers, Unit Tests, and Test-Kitchen'
task local: %w(style unit integration)

desc 'Autocorrect Rubocop Style errors'
task auto_correct: %w(style:ruby:auto_correct)
