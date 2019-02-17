module Routes
  class VirtualMachines < Sinatra::Base
    before do
      content_type :json
    end

    # List all virtual machines
    get '/virtual_machines' do
      VirtualMachine.all.map(&:as_json).to_json
    end

    # Show a single virtual machine
    get '/virtual_machines/:uuid' do
      vm = VirtualMachine.find_by(id: params[:uuid])
      halt 404 unless vm
      vm.to_json
    end

    # Create a new virtual machine
    post '/virtual_machines' do
      vm = VirtualMachine.create(
        memory: data[:memory],
        cpus: data[:cpus],
      )

      vm.to_json
    end

    # Update an existing virtual machine
    patch '/virtual_machines/:uuid' do
      vm = VirtualMachine.find_by(id: params[:uuid])
      halt 404 unless vm

      if data[:state]
        operation = case data[:state]
                    when 'started'
                      :start
                    when 'shutdown'
                      :shutdown
                    when 'halted'
                      :halt
                    else
                      halt 422
                    end

        vm.public_send(operation)
      end
    end

    # Delete a virtual machine
    delete '/virtual_machines/:uuid' do
      vm = VirtualMachine.find_by(id: params[:uuid])
      halt 404 unless vm
      vm.destroy
    end

    private

    def data
      @data ||= JSON.parse(request.body.read, symbolize_names: true)
    end
  end
end
