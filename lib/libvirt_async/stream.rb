module LibvirtAsync
  class Stream

    class RecvError < StandardError
    end

    include LibvirtAsync::WithDbg

    # @param args [Array] arguments.
    # @yield on complete or error (args: success [Boolean], ...).
    # @return [LibvirtAsync::Stream] stream object to track state.
    def self.call(*args, &block)
      new(*args, &block).call
    end

    attr_reader :state

    # @param connection [Libvirt::Connection]
    # @yield on complete or error (args: success [Boolean], error_reason [String])
    # @return [LibvirtAsync::Stream]
    def initialize(connection, &block)
      @callback = block
      @connection = connection
      @state = 'pending'
      @stream = nil
    end

    def call
      dbg { "#{to_s}#call" }
      @stream = @connection.stream(Libvirt::Stream::NONBLOCK)
      on_stream_create

      task = LibvirtAsync::Util.create_task do
        @stream.event_add_callback(
            Libvirt::Stream::EVENT_READABLE,
            method(:screenshot_callback).to_proc,
            self
        )
        dbg { "#{to_s}#call Async callback added" }
      end

      dbg { "#{to_s}#call invokes fiber=0x#{task.fiber.object_id.to_s(16)}" }
      task.run
      dbg { "#{to_s}#call ends" }

      self
    rescue Libvirt::Error => e
      dbg { "#{to_s}#call error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @state = 'failed'
      @stream&.finish rescue nil
      on_error(e)
    end

    def cancel
      dbg { "#{to_s}#cancel" }
      return if @stream.nil?

      @state = 'cancelled'
      @stream.event_remove_callback
      @stream.finish
      @stream = nil
    rescue Libvirt::Error => e
      dbg { "#{to_s}#cancel error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @stream = nil
    ensure
      on_cancel
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} @state=#{@state}>"
    end

    def inspect
      to_s
    end

    private

    def on_stream_create
      # override me
    end

    def on_cancel
      # override me
    end

    def on_error(error)
      @callback.call(false, "#{error.class}: #{error.message}")
    end

    def on_data(data)
      # override me
    end

    def on_complete
      @callback.call(true, nil)
    end

    # @param stream [Libvirt::Stream]
    # @param events [Integer]
    # @param _opaque [LibvirtAsync::Stream]
    def screenshot_callback(stream, events, _opaque)
      dbg { "#{to_s}#screenshot_callback events=#{events}" }
      return unless (Libvirt::Stream::EVENT_READABLE & events) != 0

      code, data = stream.recv(1024)
      dbg { "#{to_s}#screenshot_callback recv code=#{code}, size=#{data&.size}" }

      case code
      when 0
        dbg { "#{to_s}#screenshot_callback finished" }
        stream.finish
        @state = 'completed'
        on_complete
      when -1
        dbg { "#{to_s}#screenshot_callback code -1" }
        raise RecvError, 'error code -1 received'
      when -2
        dbg { "#{to_s}#screenshot_callback is not ready" }
      else
        dbg { "#{to_s}#screenshot_callback ready" }
        on_data(data)
      end

    rescue RecvError, Libvirt::Error => e
      dbg { "#{to_s}#screenshot_callback error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @state = 'failed'
      stream.finish rescue nil
      on_error(e)
    end
  end
end
