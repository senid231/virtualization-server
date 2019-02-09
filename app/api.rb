require 'sinatra'
require 'libvirt'

require_relative 'models'
require_relative 'models/virtual_machine'

require_relative 'routes'
require_relative 'routes/virtual_machines'

module NeptuneNetworks
  module Virtualization
    class API < Sinatra::Application
      use Routes::VirtualMachines
    end
  end
end
