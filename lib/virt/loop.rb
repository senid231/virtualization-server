# this program demonstrates the use of the libvirt event APIs.  This example
# is very, very complicated because:
# 1) the libvirt event APIs are complicated and
# 2) it tries to simulate a multi-threaded UI program, leading to some weirdness

require 'libvirt'

module Virt
  class Loop
    class Handle
      # represents an event handle (usually a file descriptor).  When an event
      # happens to the handle, we dispatch the event to libvirt via
      # Libvirt::event_invoke_handle_callback (feeding it the handle_id we returned
      # from add_handle, the file descriptor, the new events, and the opaque
      # data that libvirt gave us earlier)
      attr_accessor :handle_id, :fd, :events
      attr_reader :opaque

      def initialize(handle_id, fd, events, opaque)
        puts "Virt::Loop::Handle.initialize"
        @handle_id = handle_id
        @fd = fd
        @events = events
        @opaque = opaque
      end

      def dispatch(events)
        puts "Virt::Loop::Handle#dispatch events #{events}"
        Libvirt::event_invoke_handle_callback(@handle_id, @fd, events, @opaque)
      end
    end

    class Timer
      # represents a timer.  When a timer expires, we dispatch the event to
      # libvirt via Libvirt::event_invoke_timeout_callback (feeding it the timer_id
      # we returned from add_timer and the opaque data that libvirt gave us
      # earlier)
      attr_accessor :lastfired, :interval
      attr_reader :timer_id, :opaque

      def initialize(timer_id, interval, opaque)
        puts "Virt::Loop::Timer.initialize"
        @timer_id = timer_id
        @interval = interval
        @opaque = opaque
        @lastfired = 0
      end

      def dispatch
        puts "Virt::Loop::Timer#dispatch"
        Libvirt::event_invoke_timeout_callback(@timer_id, @opaque)
      end
    end

    def initialize
      puts "Virt::Loop#initialize"
      @next_handle_id = 1
      @next_timer_id = 1
      @handles = []
      # a bit of oddness having to do with signalling.  Since signals are
      # unreliable in a multi-threaded program, create a "self-pipe".  The read
      # end of the pipe will be part of the pollin array, and will be selected
      # on during "run_once".  The write end of the pipe is available to the
      # callbacks registered with libvirt.  When libvirt does an add, update,
      # or remove of either a handle or a timer, the callbacks will write a single
      # byte (via the interrupt method) to the write end of the pipe.  This will
      # cause the select loop in "run_once" to wakeup and recalculate the
      # polling arrays and timers based on the new information.
      @rdpipe, @wrpipe = IO.pipe
      @pending_wakeup = false
      @running_poll = false
      @quit = false

      @timers = []

      @pollin = []
      @pollout = []
      @pollerr = []
      @pollhup = []

      @pollin << @rdpipe
      register_handlers
    end

    def run_loop
      # run "run_once" forever
      puts "Virt::Loop#run_loop"
      while true
        run_once
      end
    end

    private

    def next_timeout
      # calculate the smallest timeout of all of the registered timeouts
      nexttimer = 0
      @timers.each do |t|
        puts "Virt::Loop#next_timeout, timer #{t.timer_id} last #{t.lastfired} interval #{t.interval}"
        next if t.interval < 0
        if nexttimer == 0 || (t.lastfired + t.interval) < nexttimer
          nexttimer = t.lastfired + t.interval
        end
      end

      nexttimer
    end

    def print_pollers
      # debug function to print the polling arrays
      print "pollin: ["
      @pollin.each { |x| print "#{x.fileno}, " }
      puts "]"
      print "pollout: ["
      @pollin.each { |x| print "#{x.fileno}, " }
      puts "]"
      print "pollerr: ["
      @pollin.each { |x| print "#{x.fileno}, " }
      puts "]"
    end

    def run_once
      # the main loop of the program.  This loop first calculates the smallest
      # timeout value (via next_timeout).  Based on that, it knows how long to
      # sleep for in the select (it sleeps forever if there are no timers
      # registered).  It then does a select on all of the registered file
      # descriptors, waking up if one of them becomes active or we hit the
      # timeout.  If one of the file descriptors becomes active, we properly
      # dispatch the handle event to libvirt.  If we woke up because of a timeout
      # we dispatch the timeout callback to libvirt.
      puts "Virt::Loop#run_once"

      sleep = -1
      @running_poll = true
      nexttimer = next_timeout
      puts "Virt::Loop Next timeout at #{nexttimer}"

      if nexttimer > 0
        now = Time.now.to_i * 1000
        if now >= nexttimer
          sleep = 0
        else
          sleep = (nexttimer - now) / 1000.0
        end
      end

      if sleep < 0
        puts "Virt::Loop IO.select"
        events = IO.select(@pollin, @pollout, @pollerr)
      else
        events = IO.select(@pollin, @pollout, @pollerr, sleep)
      end

      puts "Virt::Loop IO.select ok"

      print_pollers

      unless events.nil?
        puts "Virt::Loop after poll, 0 #{events[0]}, 1 #{events[1]}, 2 #{events[2]}"
        (events[0] + events[1] + events[2]).each do |io|
          if io.fileno == @rdpipe.fileno
            @pending_wakeup = false
            pipe = @rdpipe.read(1)
            next
          end

          @handles.each do |handle|
            if handle.fd == io.fileno
              libvirt_events = 0
              if events[0].include?(io)
                libvirt_events |= Libvirt::EVENT_HANDLE_READABLE
              elsif events[1].include?(io)
                libvirt_events |= Libvirt::EVENT_HANDLE_WRITABLE
              elsif events[2].include?(io)
                libvirt_events |= Libvirt::EVENT_HANDLE_ERROR
              end
              handle.dispatch(libvirt_events)
            end
          end
        end
      end

      now = Time.now.to_i * 1000
      @timers.each do |t|
        next if t.interval < 0

        want = t.lastfired + t.interval
        if now >= (want - 20)
          t.lastfired = now
          t.dispatch
        end
      end

      @running_poll = false
    end

    def interrupt
      # write a byte to the internal pipe to wake up "run_once" for recalculation.
      # See initialize for more information about the internal pipe
      puts "Virt::Loop#interrupt"
      if @running_poll and not @pending_wakeup
        @pending_wakeup = true
        @wrpipe.write('c')
      end
    end

    def register_fd(fd, events)
      # given an fd and a set of libvirt events, register the fd in the
      # appropriate polling arrays.  These arrays are used in "run_once" to
      # determine what to poll on
      puts "Virt::Loop#register_fd fd #{fd} events #{events}"
      if (events & Libvirt::EVENT_HANDLE_READABLE) != 0
        @pollin << IO.new(fd, 'r')
      end
      if (events & Libvirt::EVENT_HANDLE_WRITABLE) != 0
        @pollout << IO.new(fd, 'w')
      end
      if (events & Libvirt::EVENT_HANDLE_ERROR) != 0
        @pollerr << IO.new(fd, 'r')
      end
      if (events & Libvirt::EVENT_HANDLE_HANGUP) != 0
        @pollhup << IO.new(fd, 'r')
      end
    end

    def unregister_fd(fd)
      # remove an fd from all of the poll arrays.  run_once will no longer select
      # on this fd
      puts "Virt::Loop#unregister_fd fd #{fd}"
      @pollin.delete_if { |x| x.fileno == fd }
      @pollout.delete_if { |x| x.fileno == fd }
      @pollerr.delete_if { |x| x.fileno == fd }
      @pollhup.delete_if { |x| x.fileno == fd }
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
      puts "Virt::Loop#add_handle fd #{fd}"
      handle_id = @next_handle_id + 1
      @next_handle_id = handle_id
      @handles << Virt::Loop::Handle.new(handle_id, fd, events, opaque)
      register_fd(fd, events)
      interrupt
      handle_id
    end

    def update_handle(handle_id, events)
      # update a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and the new events.  It
      # is our responsibility to find the correct handle and update the events
      # it cares about
      puts "Virt::Loop#update_handle handle_id #{handle_id}, events #{events}"

      handle = @handles.detect { |h| h.handle_id == handle_id }
      handle.events = events
      puts "Virt::Loop updating handle_id #{handle_id} with fd #{handle.fd}"
      unregister_fd(handle.fd)
      register_fd(handle.fd, events)
      interrupt
      nil
    end

    def remove_handle(handle_id)
      # remove a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and it is our
      # responsibility to "forget" the handle.  We must return the opaque data
      # that libvirt handed us in "add_handle", otherwise we will leak memory
      puts "Virt::Loop#remove_handle handle_id #{handle_id}"
      idx = @handlers.index { |h| h.handle_id == handle_id }
      handle = @handlers.delete_at(idx)
      puts "Virt::Loop Remove handle_id #{handle.handle_id} fd #{handle.fd}"
      interrupt
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
      puts "Virt::Loop.add_timer interval #{interval}"
      timer_id = @next_timer_id + 1
      @next_timer_id = timer_id
      @timers << Virt::Loop::Timer.new(timer_id, interval, opaque)
      interrupt
      timer_id
    end

    def update_timer(timer_id, interval)
      # update a previously registered timer.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and the new interval.  It
      # is our responsibility to find the correct timer and update the timers
      # it cares about
      puts "Virt::Loop#update_timer timer_id #{timer_id} interval #{interval}"
      timer = @timers.detect { |t| t.timer_id == timer_id }
      puts "Virt::Loop updating timer #{timer.timer_id}"
      timer.interval = interval
      interrupt
      nil
    end

    def remove_timer(timer_id)
      # remove a previously registered timeout.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and it is our
      # responsibility to "forget" the timer.  We must return the opaque data
      # that libvirt handed us in "add_timer", otherwise we will leak memory
      puts "Virt::Loop#remove_timer"

      idx = @timers.index { |t| t.timer_id == timer_id }
      timer = @timers.delete_at(idx)
      puts "Virt::Loop Remove timer #{timer.timer_id}"
      interrupt
      timer.opaque
    end

    def register_handlers
      Libvirt::event_register_impl(
          method(:add_handle).to_proc,
          method(:update_handle).to_proc,
          method(:remove_handle).to_proc,
          method(:add_timer).to_proc,
          method(:update_timer).to_proc,
          method(:remove_timer).to_proc
      )
    end
  end
end
