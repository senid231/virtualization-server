require 'pp'
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

    include LibvirtAsync::WithDbg

    def self.all
      dbg { "#{name}.all" }
      domains=[]

      ::Hypervisor.all.each do |hypervisor|
        dbg { "#{name}.all hypervisor.id=#{hypervisor.id}" }
        hypervisor_domains = hypervisor.connection.list_all_domains
        dbg { "#{name}.all hypervisor.id=#{hypervisor.id} hypervisor_domains.size=#{hypervisor_domains.size}" }
        domains.concat hypervisor_domains.map { |domain| new(domain, hypervisor) }
      end

      dbg { "#{name}.all return domains.size=#{domains.size}" }
      domains
    end

    def self.find_by(id:)
      dbg { "#{name}.find_by id=#{id}" }

      ::Hypervisor.all.each do |hypervisor|
        dbg { "#{name}.find_by hypervisor.id=#{hypervisor.id}" }
        domain = hypervisor.connection.lookup_domain_by_uuid(id)
        if domain.nil?
          dbg { "#{name}.find_by not found hypervisor.id=#{hypervisor.id}" }
        else
          dbg { "#{name}.find_by found hypervisor.id=#{hypervisor.id} domain.name=#{domain.name}" }
          return new(domain, hypervisor)
        end
      end

      dbg { "#{name}.find_by not found id=#{id}" }
      nil
    end

    # def self.create(attrs)
    #   factory = DomainFactory.new(memory: attrs[:memory], cpus: attrs[:cpus])
    #   domain  = CLIENT.define_domain_xml(factory.to_xml)
    #   new(domain)
    # end

    def initialize(domain, hypervisor)
      @domain = domain
      @hypervisor = hypervisor
    end

    # def start
    #   domain.create
    # rescue Libvirt::Error => exception
    #   case exception.libvirt_message
    #   when 'Requested operation is not valid: domain is already running'
    #     return domain
    #   end
    # end
    #
    # def shutdown
    #   domain.shutdown if running?
    # end
    #
    # def halt
    #   domain.destroy if running?
    # end
    #
    # def update
    #   raise NotImplementedError
    # end
    #
    # def destroy
    #   shutdown if running?
    #   domain.undefine
    # end

    def id
      domain.uuid
    end

    def name
      domain.name
    end

    def hostname
      domain.hostname
    end

    def hypervisor
      @hypervisor
    end

    def xml
      domain.xml_desc
    end

    def state
      dbg { "#{self.class}#state retrieving id=#{id}" }
      libvirt_state, _ = domain.state
      dbg { "#{self.class}#state retrieved id=#{id} libvirt_state=#{libvirt_state}" }
      STATES[libvirt_state]
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

    def screenshot
      # filename = "/tmp/libvirt_domain_#{id}.png"
      stream = Libvirt::Stream.new
      domain.screenshot(stream, 0)
    end

    private

    attr_reader :domain
  end
end
