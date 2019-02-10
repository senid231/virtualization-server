class VirtualizationServer
  class << self
    attr_accessor :libvirt_domain_type

    def environment
      ENV.fetch('RACK_ENV')
    end
  end
end
