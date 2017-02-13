if defined?(ChefSpec)
  # DefineMatcher allow us to expose the concept of the method to chef_run during testing.
  ChefSpec.define_matcher(:veeam_catalog)

  def install_veeam_catalog(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_catalog, :install, resource_name)
  end

end
