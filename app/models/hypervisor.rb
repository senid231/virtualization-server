class Hypervisor
  include JSONAPI::Serializer

  attr_reader :id, :name, :uri, :connection, :version, :libversion, :hostname, :max_vcpus,
              :cpu_model, :cpus, :mhz, :numa_nodes, :cpu_sockets, :cpu_cores, :cpu_threads,
              :total_memory, :free_memory, :capabilities



  def self.all
    ::Configuration.instance.hypervisors
  end

  def self.find_by(id:)
    p id
    return ::Configuration.instance.hypervisors_hash[id]
  end

  def initialize(id, name, uri)
    @id = id
    @name = name
    @uri = uri
    #
    # $eventLoop = VirEventLoop.new
    #
    # Thread.abort_on_exception = true
    #
    # $virEventAddHandleImpl = lambda {|fd, events, opaque|
    #   puts "PROG: virEventAddHandleImpl"
    #   return $eventLoop.add_handle(fd, events, opaque)
    # }
    #
    # $virEventUpdateHandleImpl = lambda { |watch, event|
    #   puts "PROG: virEventUpdateHandleImpl"
    #   return $eventLoop.update_handle(watch, event)
    # }
    #
    # $virEventRemoveHandleImpl = lambda { |handleID|
    #   puts "PROG: virEventRemoveHandleImpl"
    #   return $eventLoop.remove_handle(handleID)
    # }
    #
    # $virEventAddTimerImpl = lambda { |interval, opaque|
    #   puts "PROG: virEventAddTimerImpl"
    #   return $eventLoop.add_timer(interval, opaque)
    # }
    #
    # $virEventUpdateTimerImpl = lambda { |timer, timeout|
    #   puts "PROG: virEventUpdateTimerImpl"
    #   return $eventLoop.update_timer(timer, timeout)
    # }
    #
    # $virEventRemoveTimerImpl = lambda { |timerID|
    #   puts "PROG: virEventRemoveTimerImpl"
    #   return $eventLoop.remove_timer(timerID)
    # }
    #
    # # register the handle implementations with libvirt.  Each callback is
    # # either a Symbol to a function or a Proc.
    #
    # Libvirt::event_register_impl($virEventAddHandleImpl,
    #                              $virEventUpdateHandleImpl,
    #                              $virEventRemoveHandleImpl,
    #                              $virEventAddTimerImpl,
    #                              $virEventUpdateTimerImpl,
    #                              $virEventRemoveTimerImpl)
    #
    #
    # @connection = Libvirt::open(uri)
    # p "connected"
    #
    #
    # $dom_event_callback_reboot = lambda { |conn, dom, opaque|
    #   puts "PROG: dom_event_callback_reboot: conn #{conn}, dom #{dom}, opaque #{opaque}"
    # }
    #
    #
    # cb3 = @connection.domain_event_register_any(Libvirt::Connect::DOMAIN_EVENT_ID_REBOOT,
    #                                      $dom_event_callback_reboot)
    #
    # Thread.new {
    #   $eventLoop.run_loop()
    # }
  end


  def connection
    @connection ||=_open_connection
  end

  def to_json(opts = nil)
    as_json.to_json
  end

  def as_json
    {
        id: @id,
        name: @name
    }
  end

  private

  def _open_connection
    if ::Configuration.instance.libvirt_rw
      p "Opening RW connection to #{name}"
      c = Libvirt::open(uri)
    else
      p "Opening RO connection to #{name}"
      c = Libvirt::open_read_only(uri)
    end

    #c.keepalive=[10,2]

    @version=c.version
    @libversion=c.libversion
    @hostname=c.hostname
    @max_vcpus=c.max_vcpus

    node_info=c.node_info
    @cpu_model=node_info.model
    @cpus=node_info.cpus
    @mhz=node_info.mhz
    @numa_nodes=node_info.nodes
    @cpu_sockets=node_info.sockets
    @cpu_cores=node_info.cores
    @cpu_threads=node_info.threads
    @total_memory=node_info.memory
    @free_memory=node_info.memory
    @capabilities = c.capabilities


    return c
  end



end
