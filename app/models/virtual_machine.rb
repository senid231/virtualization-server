class VirtualMachine
  extend Forwardable

  ADAPTER_CLASS = LibvirtAdapter::Domain

  def self.all
    ADAPTER_CLASS.all.map do |vm|
      new(
        id: vm.id,
        state: vm.state,
        cpus: vm.cpus,
        memory: vm.memory,
        adapter: vm
      )
    end
  end

  def self.find_by(id:)
    vm = ADAPTER_CLASS.find_by(id: id)
    return unless vm

    new(
      id: vm.id,
      state: vm.state,
      cpus: vm.cpus,
      memory: vm.memory,
      adapter: vm
    )
  end

  def self.create(attrs)
    vm = ADAPTER_CLASS.create(attrs)

    new(
      id: vm.id,
      state: vm.state,
      cpus: vm.cpus,
      memory: vm.memory,
      adapter: vm
    )
  end

  def initialize(id:, state: nil, cpus:, memory:, adapter: ADAPTER)
    @id       = id
    @state    = state
    @cpus     = cpus
    @memory   = memory
    @adapter  = adapter
  end

  def_delegators :adapter, :start, :shutdown, :halt, :update, :destroy

  def to_json(opts = nil)
    as_json.to_json
  end

  def as_json
    {
      id: @id,
      state: @state,
      cpus: @cpus,
      memory: @memory,
    }
  end

  private

  attr_reader :adapter
end
