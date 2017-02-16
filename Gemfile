# This gemfile provides additional gems for testing and releasing this cookbook
# It is meant to be installed on top of ChefDK which provides the majority
# of the necessary gems for testing this cookbook
#
# Run 'chef exec bundle install' to install these dependencies

source 'https://rubygems.org'

gem 'berkshelf', '5.6.2'

group :test do
  gem 'chefspec'
  gem 'community_cookbook_releaser'
  gem 'cookstyle'
  gem 'foodcritic'
  gem 'inspec'
  gem 'kitchen-inspec'
  gem 'kitchen-vagrant'
  gem 'rake'
  gem 'stove'
  gem 'test-kitchen'
  gem 'tomlrb'
  gem 'winrm-elevated', '~> 1.0'
end
