require_relative 'stream'

module LibvirtAsync
  class ScreenshotStream < Stream

    # @param domain [Libvirt::Domain] domain object.
    def initialize(connection, domain, &block)
      super(connection, &block)

      @domain = domain
      @file = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} @state=#{@state} @domain.uuid=#{@domain&.uuid}>"
    end

    private

    def on_cancel
      @file&.close
      @file = nil
    end

    def on_stream_create
      mime_type = @domain.screenshot(@stream, 0)
      @file = Tempfile.new("screenshot_#{@domain.uuid}", nil, mode: File::Constants::BINARY)
      dbg { "#{to_s}#call initiated mime_type=#{mime_type}, file_path=#{@file.path}" }
    end

    def on_error(error)
      @callback.call(false, "#{error.class}: #{error.message}", nil)
    end

    def on_data(data)
      @file.write(data)
    end

    def on_complete
      @file.close
      @callback.call(true, nil, @file)
    end

  end
end
