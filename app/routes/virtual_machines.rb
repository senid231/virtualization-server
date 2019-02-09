module NeptuneNetworks::Virtualization
  module Routes
    class VirtualMachines < Sinatra::Base
      before do
        content_type :json
      end

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

      # List all virtual machines
      get '/virtual_machines' do
        domains = libvirt.list_all_domains
        domains.map do |domain|
          state = STATES[domain.state.first]
          cpu_count = state == 'running' ? domain.max_vcpus : domain.vcpus.count

          {
            name: domain.name,
            uuid: domain.uuid,
            state: state,
            cpus: cpu_count,
            memory: domain.max_memory,
          }.to_json
        end
      end

      # Show a single virtual machine
      get '/virtual_machines/:uuid' do
        domain = libvirt.lookup_domain_by_uuid(params[:uuid])
        state = STATES[domain.state.first]
        cpu_count = state == 'running' ? domain.max_vcpus : domain.vcpus.count

        {
          name: domain.name,
          uuid: domain.uuid,
          state: state,
          cpus: cpu_count,
          memory: domain.max_memory,
        }.to_json
      end

      # Create a new virtual machine
      post '/virtual_machines' do
        #TODO
      end

      # Update an existing virtual machine
      put '/virtual_machines/:uuid' do
        #TODO
      end

      # Delete a virtual machine
      delete '/virtual_machines/:uuid' do
        #TODO
      end

      private

      def libvirt
        @libvirt ||= Libvirt::open('qemu:///session')
      end
    end
  end
end
