if defined?(ChefSpec)
  # DefineMatcher allow us to expose the concept of the method to chef_run during testing.
  ChefSpec.define_matcher(:veeam_catalog)
  ChefSpec.define_matcher(:veeam_console)
  ChefSpec.define_matcher(:veeam_server)
  ChefSpec.define_matcher(:veeam_prerequisites)
  ChefSpec.define_matcher(:veeam_proxy)
  ChefSpec.define_matcher(:veeam_upgrade)

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

  def install_veeam_upgrade(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_upgrade, :install, resource_name)
  end

  def add_veeam_proxy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_proxy, :add, resource_name)
  end

  def remove_veeam_proxy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:veeam_proxy, :remove, resource_name)
  end

end
