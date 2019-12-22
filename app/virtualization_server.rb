module VirtualizationServer
  def libvirt_domain_type
    @libvirt_domain_type
  end

  def libvirt_domain_type=(val)
    @libvirt_domain_type = val
  end

  def environment
    ENV.fetch('RACK_ENV')
  end

  module_function :libvirt_domain_type, :libvirt_domain_type=, :environment
end
