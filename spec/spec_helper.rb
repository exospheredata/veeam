require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'windows_helper.rb'

at_exit { ChefSpec::Coverage.report! }
