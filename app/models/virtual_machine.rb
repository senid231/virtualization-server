module NeptuneNetworks::Virtualization
  module Models
    class VirtualMachine
      class << self
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

        def from_libvirt(domains)
          if domains.is_a?(Array)
            domains.map do |domain|
              new(
                uuid: domain.uuid,
                state: state(domain),
                cpu_count: cpu_count(domain),
                memory_size: domain.max_memory
              )
            end
          else
            domain = domains
            new(
              uuid: domain.uuid,
              state: state(domain),
              cpu_count: cpu_count(domain),
              memory_size: domain.max_memory
            )
          end
        end

        private

        def state(domain)
          STATES[domain.state.first]
        end

        def cpu_count(domain)
          if state(domain) == 'running'
            domain.max_vcpus
          else
            domain.vcpus.count
          end
        end
      end

      attr_reader :uuid, :state, :cpu_count, :memory_size, :nics, :disks

      def initialize(uuid:, state:, cpu_count:, memory_size:, nics: [], disks: [])
        @uuid         = uuid
        @state        = state
        @cpu_count    = cpu_count
        @memory_size  = memory_size
        @nics         = nics
        @disks        = disks
      end

      def to_json(opts = nil)
        {
          uuid: uuid,
          state: state,
          cpu_count: cpu_count,
          memory_size: memory_size,
          nics: nics.map(&:to_json),
          disks: disks.map(&:to_json)
        }.to_json
      end

      def to_xml
        [metadata_xml, nics_xml, disks_xml, closing_xml].join
      end

      private

      def metadata_xml
        <<~XML
          <domain type='kvm'>
            <name>#{uuid}</name>
            <uuid>#{uuid}</uuid>
            <memory>#{memory_size}</memory>
            <currentMemory>#{memory_size}</currentMemory>
            <vcpu>#{cpu_count}</vcpu>
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

      def nics_xml
        nics.map do |nic|
          <<~XML
            <interface type='bridge'>
              <source bridge='#{nic.bridge}'/>
              <mac address="#{nic.mac_address}"/>
              <model type='virtio'/>
            </interface>
          XML
        end
      end

      def disks_xml
        disks.map do |disk|
          <<~XML
            <disk type='file' device='disk'>
              <driver name="qemu" type="qcow2"/>
              <source file='#{disk.path}'/>
              <target dev='hda' bus='ide'/>
            </disk>
          XML
        end
      end
    end
  end
end
