require './config/environment'

module NeptuneNetworks
  class VirtualizationServer
    class API < Sinatra::Application
      use ::Routes::VirtualMachines
    end
  end
end
