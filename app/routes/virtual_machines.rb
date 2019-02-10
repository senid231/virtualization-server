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
        domain = domain_or_404!
        Models::VirtualMachine.from_libvirt(domain).to_json
      end

      # Create a new virtual machine
      post '/virtual_machines' do
        vm = Models::VirtualMachine.new(
          cpu_count: data[:cpu_count],
          memory_size: data[:memory_size],
        )

        if domain = libvirt.define_domain_xml(vm.to_xml)
          domain.create
          vm.to_json
        else
          halt 422
        end
      end

      # Update an existing virtual machine
      patch '/virtual_machines/:uuid' do
        domain = domain_or_404!

        operation = case data[:state]
                    when 'started'
                      :create
                    when 'stopped'
                      :shutdown
                    when 'halted'
                      :destroy
                    else
                      halt 422
                    end

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
        domain = domain_or_404!
        domain.destroy if domain.active?
        domain.undefine
      end

      private

      def domain_or_404!
        libvirt.lookup_domain_by_uuid(params[:uuid])
      rescue => exception
        case exception.libvirt_code
        when 8
          halt 404
        when 42
          halt 404
        end
      end

      def data
        @data ||= JSON.parse(request.body.read, symbolize_names: true)
      end

      def libvirt
        @libvirt ||= Libvirt::open('qemu:///session')
      end
    end
  end
end
