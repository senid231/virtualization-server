require './config/environment'
require 'sinatra/jsonapi'

class VirtualizationServer
  class API < Sinatra::Base
#   class API < Sinatra::Application
#     use ::Routes::VirtualMachines
#     use ::Routes::Hypervisors
#   end
#
register Sinatra::JSONAPI
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
  end

  resource :virtual_machines, pkre: /[\w-]+/ do
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

  end

  resource :starts do
    index do
      VIRT_RUNNER = Virt::Runner.new.run
      clusters = YAML.load_file(File.join(__dir__, 'config', 'cluster.yml'))
      Hypervisor.load_storage(clusters)

      Hypervisor.all.each do |hv|
        puts "Hypervisor #{hv.id} #{hv.name} #{hv.uri}"
      end

      []
    end
  end

  freeze_jsonapi
  end
end
