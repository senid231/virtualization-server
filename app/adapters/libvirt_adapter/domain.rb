module LibvirtAdapter
  class Domain
    # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainState
    STATES = {
      0 => "no state",
      1 => "running",
      2 => "blocked on resource",
      3 => "paused by user",
      4 => "being shut down",
      5 => "shut off",
      6 => "crashed",
      7 => "suspended by guest power management",
    }

    def self.all
      CLIENT.list_all_domains.map { |domain| new(domain) }
    end

    def self.find_by(id:)
      vm = CLIENT.lookup_domain_by_uuid(id)
      new(vm)
    rescue Libvirt::RetrieveError
      nil
    end

    def self.create(attrs)
      factory = DomainFactory.new(memory: attrs[:memory], cpus: attrs[:cpus])
      domain  = CLIENT.define_domain_xml(factory.to_xml)
      new(domain)
    end

    def initialize(domain)
      @domain = domain
    end

    def start
      domain.create
    rescue Libvirt::Error => exception
      case exception.libvirt_message
      when 'Requested operation is not valid: domain is already running'
        return domain
      end
    end

    def shutdown
      domain.shutdown if running?
    end

    def halt
      domain.destroy if running?
    end

    def update
      raise NotImplementedError
    end

    def destroy
      shutdown if running?
      domain.undefine
    end

    def id
      domain.uuid
    end

    def state
      STATES[domain.state.first]
    end

    def running?
      state == STATES[1]
    end

    def cpus
      if running?
        domain.max_vcpus
      else
        domain.vcpus.count
      end
    end

    def memory
      domain.max_memory
    end

    private

    attr_reader :domain
  end
end
