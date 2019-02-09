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
      patch '/virtual_machines/:uuid' do
        #TODO
      end

      # Change the state of the virtual machine
      put '/virtual_machines/:uuid' do
        operation = case data[:state]
                    when 'start'
                      :create
                    when 'stop'
                      :shutdown
                    when 'halt'
                      :destroy
                    else
                      halt 422
                    end

        domain = libvirt.lookup_domain_by_uuid(params[:uuid])

        begin
          domain.public_send(operation)
        rescue Libvirt::Error => exception
          case exception.libvirt_code
          when 55
            # Already in the requested state
            status 200
          else
            raise
          end
        end
      end

      # Delete a virtual machine
      delete '/virtual_machines/:uuid' do
        #TODO
      end

      private

      def data
        @data ||= JSON.parse(request.body.read, symbolize_names: true)
      end

      def libvirt
        @libvirt ||= Libvirt::open('qemu:///session')
      end
    end
  end
end
