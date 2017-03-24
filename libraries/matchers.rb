if defined?(ChefSpec)
  # DefineMatcher allow us to expose the concept of the method to chef_run during testing.
  ChefSpec.define_matcher(:veeam_catalog)
  ChefSpec.define_matcher(:veeam_console)
  ChefSpec.define_matcher(:veeam_server)
  ChefSpec.define_matcher(:veeam_prerequisites)

  def install_veeam_catalog(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_catalog, :install, resource_name)
  end

  def install_veeam_console(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_console, :install, resource_name)
  end

  def install_veeam_server(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_server, :install, resource_name)
  end

  def install_veeam_prerequisites(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_prerequisites, :install, resource_name)
  end

  def install_veeam_explorer(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_explorer, :install, resource_name)
  end

end
