module LibvirtAdapter
  class DomainFactory
    def initialize(memory: 1024 * 1024 * 1, cpus: 1)
      @id     = SecureRandom.uuid
      @memory = memory
      @cpus   = cpus
    end

    def to_xml
      [starting_xml, closing_xml].join
    end

    private

    def starting_xml
      <<~XML
      <domain type='#{VirtualizationServer.libvirt_domain_type}'>
        <name>#{@id}</name>
        <uuid>#{@id}</uuid>
        <memory>#{@memory}</memory>
        <currentMemory>#{@memory}</currentMemory>
        <vcpu>#{@cpus}</vcpu>
        <os>
          <type arch='x86_64' machine='pc'>hvm</type>
          <boot dev='hd'/>
        </os>
        <features>
          <acpi/>
          <apic/>
          <pae/>
        </features>
        <clock offset='localtime'/>
        <on_poweroff>preserve</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>restart</on_crash>
        <devices>
      XML
    end

    def closing_xml
      <<~XML
          <graphics type='vnc' port='-1' autoport='yes' passwd='virtualmachinesarecool'/>
        </devices>
      </domain>
      XML
    end
  end
end
