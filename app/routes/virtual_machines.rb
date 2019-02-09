module NeptuneNetworks::Virtualization
  module Routes
    class VirtualMachines < Sinatra::Base
      # List all virtual machines
      get '/virtual_machines' do
        #TODO
      end

      # Show a single virtual machine
      get '/virtual_machines/:guid' do
        #TODO
      end

      # Create a new virtual machine
      post '/virtual_machines/:guid' do
        #TODO
      end

      # Update an existing virtual machine
      put '/virtual_machines/:guid' do
        #TODO
      end

      # Delete a virtual machine
      delete '/virtual_machines/:guid' do
        #TODO
      end
    end
  end
end
