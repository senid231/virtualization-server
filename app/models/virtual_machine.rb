class VirtualMachine
  extend Forwardable

  attr_reader :id, :name, :cpus, :memory, :state, :hypervisor, :xml

  ADAPTER_CLASS = LibvirtAdapter::Domain

  class_attribute :_hash, instance_writer: false, default: {}
  class_attribute :_cache, instance_writer: false, default: []

  def self.load_from_hypervisors
    self._hash = {}
    self._cache = []

    ADAPTER_CLASS.all.map do |vm|
      v = new(
        id: vm.id,
        name: vm.name,
        hypervisor: vm.hypervisor,
        state: vm.state,
        cpus: vm.cpus,
        memory: vm.memory,
        adapter: vm,
        xml: vm.xml
      )
      _cache.push(v)
      _hash[vm.id] = v
    end

    _cache
  end

  def self.all
    return _cache
  end

  def self.find_by(id:)
    return _hash[id]
  end

  def self.create(attrs)
    vm = ADAPTER_CLASS.create(attrs)

    new(
      id: vm.id,
      name: vm.name,
      hypervisor: vm.hypervisor,
      state: vm.state,
      cpus: vm.cpus,
      memory: vm.memory,
      adapter: vm,
      xml: nil
    )
  end

  def initialize(id:, name:, hypervisor:, state: nil, cpus:, memory:, adapter:, xml:)
    @id       = id
    @name     = name
    @hypervisor = hypervisor
    @state    = state
    @cpus     = cpus
    @memory   = memory
    @adapter  = adapter
    @xml = xml
  end

  def tags
    nil
  end

end
