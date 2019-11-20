require 'jsonapi-serializers'

class VirtualMachineSerializer
  include JSONAPI::Serializer

  attribute :name
  attribute :state
  attribute :memory
  attribute :cpus
  attribute :xml
  has_one :hypervisor, include_data: true, include_links: true do
    Hypervisor.find_by(id: object.hypervisor.id)
  end

end