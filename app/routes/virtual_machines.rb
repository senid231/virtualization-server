module NeptuneNetworks::Virtualization
  module Routes
    class VirtualMachines < Sinatra::Base
      before do
        content_type :json
      end

      # List all virtual machines
      get '/virtual_machines' do
        domains = libvirt.list_all_domains
        Models::VirtualMachine.from_libvirt(domains).to_json
      end

      # Show a single virtual machine
      get '/virtual_machines/:uuid' do
        domain = libvirt.lookup_domain_by_uuid(params[:uuid])
        Models::VirtualMachine.from_libvirt(domain).to_json
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
