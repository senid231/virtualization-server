module NeptuneNetworks::Virtualization
  module Routes
    class VirtualMachines < Sinatra::Base
      # List all virtual machines
      get '/virtual_machines' do
        libvirt.list_domains
      end

      # Show a single virtual machine
      get '/virtual_machines/:uuid' do
        libvirt.lookup_domain_by_uuid(params[:uuid])
      end

      # Create a new virtual machine
      post '/virtual_machines/:uuid' do
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
