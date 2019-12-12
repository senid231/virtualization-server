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
      dbg { "#{self.class}.load_storage" }
      self._storage = Hypervisor::Storage.new(config)
      dbg { "#{self.class}.load_storage loaded" }
    end

    def all
      dbg { "#{self.class}.all" }
      if _storage.nil?
        dbg { "#{self.class}.all storage not initialized" }
        return []
      end
      result = _storage.hypervisors
      dbg { "#{self.class}.all found size=#{result.size}" }
      result
    end

    def find_by(id:)
      dbg { "#{self.class}.find_by id=#{id}" }
      if _storage.nil?
        dbg { "#{self.class}.find_by storage not initialized id=#{id}" }
        return
      end
      result = _storage.hypervisors_hash[id]
      dbg { "#{self.class}.find_by found id=#{result&.id}, name=#{result&.name}, uri=#{result&.uri}" }
      result
    end
  end

  def initialize(id, name, uri)
    dbg { "#{self.class}#initialize id=#{id}, name=#{name}, uri=#{uri}" }

    @id = id
    @name = name
    @uri = uri

    #force connect to initialize events callbacks
    connection
  end

  def register_connection_event_callbacks(c)
    dbg { "#{self.class}#register_connection_event_callbacks id=#{id}, name=#{name}, uri=#{uri}" }
    c.domain_event_register_any(
        Libvirt::Connect::DOMAIN_EVENT_ID_REBOOT,
        method(:dom_event_callback_reboot).to_proc
    )
    dbg { "#{self.class}#register_connection_event_callbacks finished id=#{id}, name=#{name}, uri=#{uri}" }
  end

  def connection
    dbg { "#{self.class}#connection #{@connection.nil? ? 'absent' : 'present'} id=#{@connection}, name=#{name}, uri=#{uri}" }
    @connection ||= _open_connection(true)
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
    dbg { "#{self.class}#dom_event_callback_reboot id=#{id} conn=#{conn}, dom=#{dom}, opaque=#{opaque}" }
  end

  def _open_connection(register_events = false)
    if self.class._storage&.libvirt_rw
      dbg { "#{self.class}#_open_connection Opening RW connection to name=#{name} id=#{id}, uri=#{uri}" }
      c = Libvirt::open(uri)
    else
      dbg { "#{self.class}#_open_connection Opening RO connection to name=#{name} id=#{id}, uri=#{uri}" }
      c = Libvirt::open_read_only(uri)
    end

    dbg { "#{self.class}#_open_connection Connected name=#{name} id=#{id}, uri=#{uri}" }

    #~ c.keepalive = [10, 2]

    @version = c.version
    @libversion = c.libversion
    @hostname = c.hostname
    @max_vcpus = c.max_vcpus
    @capabilities = c.capabilities

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

    register_connection_event_callbacks(c) if register_events

    c
  end

  include AppLogger::WithDbg
end
