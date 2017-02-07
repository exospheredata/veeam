# This gemfile provides additional gems for testing and releasing this cookbook
# It is meant to be installed on top of ChefDK which provides the majority
# of the necessary gems for testing this cookbook
#
# Run 'chef exec bundle install' to install these dependencies

source 'https://rubygems.org'

gem 'berkshelf', '5.2.0'

group :test do
  gem 'cookstyle'
  gem 'foodcritic'
  gem 'tomlrb'
  gem 'rake'
  gem 'stove'
  gem 'community_cookbook_releaser'
  gem 'chefspec'
  gem 'test-kitchen'
  gem 'kitchen-vagrant'
  gem 'kitchen-inspec'
  gem 'inspec'
  gem 'winrm-elevated', '~> 1.0'
end
