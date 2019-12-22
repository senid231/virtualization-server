require 'active_support/all'
require 'sinatra/jsonapi'
require 'sinatra/custom_logger'
require_relative 'lib/async_cable'
require_relative 'config/environment'

module VirtualizationServer
  class API < Sinatra::Base
    helpers Sinatra::CustomLogger
    register Sinatra::JSONAPI

    configure do
      enable :logging
      enable :sessions

      logger =  Logger.new(STDOUT)
      logger.level = Logger::DEBUG if development?
      set :logger, logger
    end

    resource :hypervisors do
      helpers do
        def find(id)
          Hypervisor.find_by(id: id.to_i)
        end
      end

      index do
        Hypervisor.all
      end

      show do
        next resource
      end
    end #resource :hypervisors

    resource :virtual_machines, pkre: '/[\w-]+/' do
      helpers do
        def find(id)
          VirtualMachine.load_from_hypervisors
          VirtualMachine.find_by(id: id.to_s)
        end
      end

      index do
        VirtualMachine.load_from_hypervisors
        VirtualMachine.all
      end

      show do
        next resource, include: %q[hypervisor]
      end

      has_one :hypervisor do
        pluck do
          resource.hypervisor
        end
      end

    end #resource :virtual_machines

    freeze_jsonapi

  end #class API
end #class VirtualizationServer
