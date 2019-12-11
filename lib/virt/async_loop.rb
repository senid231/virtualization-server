require 'libvirt'

module Virt
  class AsyncLoop
    # https://github.com/libvirt/ruby-libvirt/blob/master/doc/site/examples/event_test.rb

    class Handle
      # represents an event handle (usually a file descriptor).  When an event
      # happens to the handle, we dispatch the event to libvirt via
      # Libvirt::event_invoke_handle_callback (feeding it the handle_id we returned
      # from add_handle, the file descriptor, the new events, and the opaque
      # data that libvirt gave us earlier)
      attr_accessor :handle_id, :fd, :events
      attr_reader :opaque

      def initialize(handle_id, fd, events, opaque)
        AppLogger.debug("0x#{object_id.to_s(16)}") { "#{self.class}#initialize handle_id=#{handle_id}, fd=#{fd}, events=#{events}" }

        @handle_id = handle_id
        @fd = fd
        @events = events
        @opaque = opaque
      end

      def dispatch(events)
        AppLogger.debug("0x#{object_id.to_s(16)}") { "#{self.class}#dispatch events handle_id=#{@handle_id} events=#{events}" }

        Libvirt::event_invoke_handle_callback(@handle_id, @fd, events, @opaque)
      end
    end

    class Timer
      # represents a timer.  When a timer expires, we dispatch the event to
      # libvirt via Libvirt::event_invoke_timeout_callback (feeding it the timer_id
      # we returned from add_timer and the opaque data that libvirt gave us
      # earlier)
      attr_accessor :last_fired, :interval
      attr_reader :timer_id, :opaque

      def initialize(timer_id, interval, opaque)
        AppLogger.debug("0x#{object_id.to_s(16)}") { "#{self.class}#initialize timer_id=#{timer_id}, interval=#{interval}" }

        @timer_id = timer_id
        @interval = interval.to_f / 1000.to_f
        @opaque = opaque
        @last_fired = 0.0
      end

      def wait_time
        return if interval < 0
        last_fired + interval
      end

      def dispatch
        AppLogger.debug("0x#{object_id.to_s(16)}") { "#{self.class}#dispatch timer_id=#{@timer_id}" }

        Libvirt::event_invoke_timeout_callback(@timer_id, @opaque)
      end
    end

    def self.run
      dbg "#{self.class}.run"

      instance = new
      instance.run
      instance
    end

    def initialize
      dbg { "#{self.class}#initialize" }

      @reactor = Async::Task.current.reactor

      @next_handle_id = 1
      @next_timer_id = 1
      @handles = []
      @timers = []
      @timer_tasks = {}
      @handle_tasks = {}
    end

    def run
      # the main loop of the program.  This loop first calculates the smallest
      # timeout value (via next_timeout).  Based on that, it knows how long to
      # sleep for in the select (it sleeps forever if there are no timers
      # registered).  It then does a select on all of the registered file
      # descriptors, waking up if one of them becomes active or we hit the
      # timeout.  If one of the file descriptors becomes active, we properly
      # dispatch the handle event to libvirt.  If we woke up because of a timeout
      # we dispatch the timeout callback to libvirt.
      dbg { "#{self.class}#run_loop" }

      register_handlers

      run_debug_log_print(1)
    end

    private

    def run_debug_log_print(timeout)
      Async do
        while true
          dbg do
            "#{self.class}#debug_log_objects\n" +
            "> next_handle_id=#{@next_handle_id}\n" +
            "> next_timer_id=#{@next_timer_id}\n" +
            "> timers(#{@timers.size})=#{@timers.map(&:timer_id).join(', ')}\n" +
            "> handles(#{@handles.size})=#{@handles.map(&:handle_id).join(', ')}\n" +
            "> timer_tasks(#{@timer_tasks.keys.size})=#{@timer_tasks.keys.join(', ')}\n" +
            "> handle_tasks(#{@handle_tasks.keys.size})=#{@handle_tasks.keys.join(', ')}"
          end

          Async::Task.current.sleep(timeout)
        end
      end
    end

    # Adds fiber to reactor that sleeps until wait_time comes.
    # After that it call Virt::AsyncLoop::Timer#dispatch.
    # @param [Virt::AsyncLoop::Timer]
    def register_timer(timer)
      dbg { "#{self.class}#register_timer timer_id=#{timer.timer_id}" }

      if timer.wait_time.nil?
        dbg { "#{self.class}#register_timer no wait time timer_id=#{timer.timer_id}, interval=#{timer.interval}" }
        return
      end

      timer_task = Async do |_task|
        dbg { "#{self.class}#register_timer Async start timer_id=#{timer.timer_id}" }
        now_time = Time.now.to_f
        timeout = timer.wait_time > now_time ? timer.wait_time - now_time : 0
        @reactor.sleep(timeout)
        dbg { "#{self.class}#register_timer Async start timer_id=#{timer.timer_id}" }
        timer.last_fired = Time.now.to_f
        timer.dispatch
      end

      @timer_tasks[timer.timer_id] = timer_task
    end

    # @param [Virt::AsyncLoop::Timer]
    def unregister_timer(timer)
      dbg { "#{self.class}#unregister_timer timer_id=#{timer.timer_id}" }

      timer_task = @timer_tasks.delete(timer.timer_id)
      timer_task.stop if timer_task.alive?
    end

    # @param [Virt::AsyncLoop::Handle]
    def register_handle(handle)
      dbg { "#{self.class}#register_handle handle_id=#{handle.handle_id}, fd=#{handle.fd}" }

      if (handle.events & Libvirt::EVENT_HANDLE_ERROR) != 0
        dbg { "#{self.class}#register_handle skip EVENT_HANDLE_ERROR handle_id=#{handle.handle_id}" }
      end
      if (handle.events & Libvirt::EVENT_HANDLE_HANGUP) != 0
        dbg { "#{self.class}#register_handle skip EVENT_HANDLE_HANGUP handle_id=#{handle.handle_id}" }
      end

      interest = events_to_interest(handle.events)
      dbg { "#{self.class}#register_handle parse handle_id=#{handle.handle_id}, fd=#{handle.fd}, events=#{handle.events}, interest=#{interest}" }

      if interest.nil?
        dbg { "#{self.class}#register_handle no interest handle_id=#{handle.handle_id}, fd=#{handle.fd}" }
        return
      end

      Async do |task|
        io_mode = interest_to_io_mode(interest)
        dbg { "#{self.class}#register_handle Async start handle_id=#{handle.handle_id}, fd=#{handle.fd}, io_mode=#{io_mode}" }
        io = IO.new(handle.fd, io_mode)
        monitor = @reactor.register(io, interest)
        @handle_tasks[handle.handle_id] = monitor
        task.yield
        events = readiness_to_events(monitor.readiness)
        dbg { "#{self.class}#register_handle Async resume readiness=#{monitor.readiness}, handle_id=#{handle.handle_id}, fd=#{handle.fd}" }

        if events.nil?
          dbg { "#{self.class}#register_handle Async not ready readiness=#{monitor.readiness}, handle_id=#{handle.handle_id}, fd=#{handle.fd}" }
        else
          handle.dispatch(events)
        end
      end
    end

    def interest_to_io_mode(interest)
      case interest
      when :rw
        'a+'
      when :r
        'r'
      when :w
        'w'
      else
        nil
      end
    end

    def readiness_to_events(readiness)
      case readiness.to_sym
      when :rw
        Libvirt::EVENT_HANDLE_READABLE | Libvirt::EVENT_HANDLE_WRITABLE
      when :r
        Libvirt::EVENT_HANDLE_READABLE
      when :w
        Libvirt::EVENT_HANDLE_WRITABLE
      else
        nil
      end
    end

    def events_to_interest(events)
      readable = (events & Libvirt::EVENT_HANDLE_READABLE) != 0
      writable = (events & Libvirt::EVENT_HANDLE_WRITABLE) != 0
      if readable && writable
        :rw
      elsif readable
        :r
      elsif writable
        :w
      else
        nil
      end
    end

    # @param [Virt::AsyncLoop::Handle]
    def unregister_handle(handle)
      dbg { "#{self.class}#unregister_handle handle_id=#{handle.handle_id}, fd=#{handle.fd}" }

      monitor = @handle_tasks.delete(handle.handle_id)
      if monitor.nil?
        dbg { "#{self.class}#unregister_handle already unregistered handle_id=#{handle.handle_id}, fd=#{handle.fd}" }
        return
      end
      monitor.close unless monitor.closed?
    end

    def add_handle(fd, events, opaque)
      # add a handle to be tracked by this object.  The application is
      # expected to maintain a list of internal handle IDs (integers); this
      # callback *must* return the current handle_id.  This handle_id is used
      # both by libvirt to identify the handle (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_handle)
      dbg { "#{self.class}#add_handle fd=#{fd}, events=#{events}" }

      @next_handle_id += 1
      handle_id = @next_handle_id
      handle = Virt::AsyncLoop::Handle.new(handle_id, fd, events, opaque)
      dbg { "#{self.class}#add_handle created handle_id=#{handle.handle_id}" }
      @handles << handle
      register_handle(handle)
      handle_id
    end

    def update_handle(handle_id, events)
      # update a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and the new events.  It
      # is our responsibility to find the correct handle and update the events
      # it cares about
      dbg { "#{self.class}#update_handle handle_id=#{handle_id}, events=#{events}" }

      handle = @handles.detect { |h| h.handle_id == handle_id }
      handle.events = events
      dbg { "#{self.class}#update_handle updating handle_id=#{handle.handle_id}, fd=#{handle.fd}" }
      unregister_handle(handle)
      register_handle(handle)
      nil
    end

    def remove_handle(handle_id)
      # remove a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and it is our
      # responsibility to "forget" the handle.  We must return the opaque data
      # that libvirt handed us in "add_handle", otherwise we will leak memory
      dbg { "#{self.class}#remove_handle #{handle_id}" }

      idx = @handles.index { |h| h.handle_id == handle_id }
      handle = @handles.delete_at(idx)
      dbg { "#{self.class}#remove_handle removing handle_id=#{handle.handle_id} fd=#{handle.fd}" }
      unregister_handle(handle)
      handle.opaque
    end

    def add_timer(interval, opaque)
      # add a timeout to be tracked by this object.  The application is
      # expected to maintain a list of internal timer IDs (integers); this
      # callback *must* return the current timer_id.  This timer_id is used
      # both by libvirt to identify the timeout (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_timer)
      dbg { "#{self.class}#add_timer interval=#{interval}" }

      @next_timer_id += 1
      timer_id = @next_timer_id
      timer = Virt::AsyncLoop::Timer.new(timer_id, interval, opaque)
      dbg { "#{self.class}#add_timer created timer_id=#{timer.timer_id}" }
      @timers << timer
      register_timer(timer)
      timer_id
    end

    def update_timer(timer_id, interval)
      # update a previously registered timer.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and the new interval.  It
      # is our responsibility to find the correct timer and update the timers
      # it cares about
      dbg { "#{self.class}#update_timer timer_id=#{timer_id}, interval=#{interval}" }

      timer = @timers.detect { |t| t.timer_id == timer_id }
      dbg { "#{self.class}#update_timer updating timer_id=#{timer.timer_id}" }
      timer.interval = interval
      unregister_timer(timer)
      register_timer(timer)
      nil
    end

    def remove_timer(timer_id)
      # remove a previously registered timeout.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and it is our
      # responsibility to "forget" the timer.  We must return the opaque data
      # that libvirt handed us in "add_timer", otherwise we will leak memory
      dbg { "#{self.class}#remove_timer timer_id=#{timer_id}" }

      idx = @timers.index { |t| t.timer_id == timer_id }
      timer = @timers.delete_at(idx)
      dbg { "#{self.class}#remove_timer removing timer_id=#{timer.timer_id}" }
      unregister_timer(timer)
      timer.opaque
    end

    def register_handlers
      dbg { "#{self.class}#register_handlers" }

      Libvirt::event_register_impl(
          method(:add_handle).to_proc,
          method(:update_handle).to_proc,
          method(:remove_handle).to_proc,
          method(:add_timer).to_proc,
          method(:update_timer).to_proc,
          method(:remove_timer).to_proc
      )
    end

    def dbg(msg = nil, &block)
      block = proc { msg } unless block_given?
      AppLogger.debug("0x#{object_id.to_s(16)}", &block)
    end

    def self.dbg(msg = nil, &block)
      block = proc { msg } unless block_given?
      AppLogger.debug("0x#{object_id.to_s(16)}", &block)
    end

  end
end
