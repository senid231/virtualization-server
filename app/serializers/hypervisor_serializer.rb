require 'jsonapi-serializers'

class HypervisorSerializer
  include JSONAPI::Serializer

  attribute :name
  attribute :version
  attribute :libversion
  attribute :hostname
  attribute :max_vcpus
  attributes :cpu_model, :cpus, :mhz, :numa_nodes, :cpu_sockets, :cpu_cores, :cpu_threads
  attributes :total_memory, :free_memory
  attribute :capabilities
end