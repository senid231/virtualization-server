module LibvirtAdapter
  class Disk
    STORAGE_LOCATION = '/var/lib/libvirt/images'.freeze

    def self.find_by(id:)
      disk = CLIENT.lookup_domain_by_uuid(id)
      new(disk)
    end

    def self.create(attrs)
      factory = DiskFactory.new(memory: attrs[:memory], cpus: attrs[:cpus])
      domain  = CLIENT.define_domain_xml(factory.to_xml)
      new(domain)
    end

    def initialize(domain)
      @domain = domain
    end
  end
end
