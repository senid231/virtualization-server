require 'libvirt'

class Hypervisor
  include JSONAPI::Serializer

  attr_reader :id, :name, :uri, :connection, :version, :libversion, :hostname, :max_vcpus,
              :cpu_model, :cpus, :mhz, :numa_nodes, :cpu_sockets, :cpu_cores, :cpu_threads,
              :total_memory, :free_memory, :capabilities

  class_attribute :_storage, instance_accessor: false

  class Storage
    attr_reader :hypervisors_hash, :libvirt_rw

    def initialize(cfg)
      @hypervisors_hash = {}
      @libvirt_rw = false

      cfg['hypervisors'].each do |hv|
        #add to hash for fast lookup
        @hypervisors_hash[hv["id"]] = Hypervisor.new(hv["id"], hv["name"], hv["uri"])
      end
    end

    def hypervisors
      @hypervisors_hash.values
    end
  end

  class << self
    def load_storage(config)
      puts 'Hypervisor.load_storage'
      self._storage = Hypervisor::Storage.new(config)
    end

    def all
      puts 'Hypervisor.all'
      return [] if _storage.nil?
      _storage.hypervisors
    end

    def find_by(id:)
      puts "Hypervisor.find id #{id}"
      return if _storage.nil?
      _storage.hypervisors_hash[id]
    end
  end

  def initialize(id, name, uri)
    @id = id
    @name = name
    @uri = uri

    @thread = Thread.new do
      connection.domain_event_register_any(
          Libvirt::Connect::DOMAIN_EVENT_ID_REBOOT,
          method(:dom_event_callback_reboot).to_proc
      )
    end
    @thread.abort_on_exception = true
  end

  def connection
    @connection ||= _open_connection
  end

  def to_json(_opts = nil)
    as_json.to_json
  end

  def as_json
    {
        id: @id,
        name: @name
    }
  end

  private

  def dom_event_callback_reboot(conn, dom, opaque)
    puts "Hypervisor(#{id})#dom_event_callback_reboot: conn #{conn}, dom #{dom}, opaque #{opaque}"
  end

  def _open_connection
    if self.class._storage&.libvirt_rw
      puts "Hypervisor #{id} Opening RW connection to #{name}"
      c = Libvirt::open(uri)
    else
      puts "Hypervisor #{id} Opening RO connection to #{name}"
      c = Libvirt::open_read_only(uri)
    end

    puts "Hypervisor #{id} connected"

    #c.keepalive=[10,2]

    @version = c.version
    @libversion = c.libversion
    @hostname = c.hostname
    @max_vcpus = c.max_vcpus

    node_info = c.node_info
    @cpu_model = node_info.model
    @cpus = node_info.cpus
    @mhz = node_info.mhz
    @numa_nodes = node_info.nodes
    @cpu_sockets = node_info.sockets
    @cpu_cores = node_info.cores
    @cpu_threads = node_info.threads
    @total_memory = node_info.memory
    @free_memory = node_info.memory
    @capabilities = c.capabilities

    c
  end

end
