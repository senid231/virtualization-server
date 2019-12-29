require 'async/websocket/adapters/rack'

module AsyncCable
  class Server
    class_attribute :logger, instance_writer: false, default: Logger.new('/dev/null')

    def initialize(connection_class:)
      @subscribers = AsyncCable::Subscribers.new
      @connection_class = connection_class
      @connection_class.subscribers = @subscribers
    end

    def call(env)
      response = Async::WebSocket::Adapters::Rack.open(env, handler: @connection_class) do |connection|
        connection.handle_open(env)

        while (data = connection.read)
          connection.handle_command(data)
        end

        connection.close_code = nil
      rescue Protocol::WebSocket::ClosedError => error
        logger.debug { "#{self.class} #{connection.to_s} receives ClosedError message=#{error.message} code=#{error.code}" }
        connection.close_code = error.code
      rescue AsyncCable::Errors::Unauthorized => error
        logger.debug { "#{self.class} #{connection.to_s} connection receives Unauthorized" }
        connection.close_code = error.code
        connection.send_close(error.code, error.message)
      rescue EOFError => e
        logger.debug { "#{self.class} #{connection.to_s} #{e.class} #{e.message}" }
        connection.close_code = 1111
      ensure
        logger.debug { "#{self.class} connection closed" }
        connection.handle_close
        connection.close
      end
      # Transform headers from Protocol::HTTP::Headers::Merged into Hash.
      # It will prevent other middleware from crash because everybody works with headers like with a Hash.
      response[1] = response[1].to_a.to_h unless response.nil?
      response || [200, {}, ['Hello World']]
    end
  end
end
