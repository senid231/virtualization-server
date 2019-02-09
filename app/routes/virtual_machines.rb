module NeptuneNetworks::Virtualization
  module Routes
    class VirtualMachines < Sinatra::Base
      get '/' do
        puts 'foo'
      end
    end
  end
end
