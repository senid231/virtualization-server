class VirtualMachine
  extend Forwardable

  attr_reader :id, :name, :cpus, :memory, :state, :hypervisor, :xml

  ADAPTER_CLASS = LibvirtAdapter::Domain

  @hash={}
  @cache=[]

  def self.load_from_hypervisors

    @hash={}
    @cache=[]

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
      @cache.push(v)
      @hash[vm.id] = v
    end
    return @cache
  end

  def self.all
    return @cache
  end

  def self.find_by(id:)
    return @hash[id]
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
      adapter: vm
    )
  end

  def initialize(id:, name:, hypervisor:, state: nil, cpus:, memory:, adapter: ADAPTER, xml:)
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

  end



end
