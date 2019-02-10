require './config/environment'

class VirtualizationServer
  class API < Sinatra::Application
    use ::Routes::VirtualMachines
  end
end
