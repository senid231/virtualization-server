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

      attr_reader :uuid, :state, :cpu_count, :memory_size

      def initialize(uuid:, state:, cpu_count:, memory_size:)
        @uuid         = uuid
        @state        = state
        @cpu_count    = cpu_count
        @memory_size  = memory_size
      end

      def to_json(opts = nil)
        {
          uuid: uuid,
          state: state,
          cpu_count: cpu_count,
          memory_size: memory_size,
        }.to_json
      end
    end
  end
end
