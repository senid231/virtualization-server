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
      result = Async::WebSocket::Adapters::Rack.open(env, handler: @connection_class) do |connection|
        connection.handle_open(env)

        while (data = connection.read)
          connection.handle_command(data)
        end

        connection.close_code = nil
      rescue Protocol::WebSocket::ClosedError => error
        logger.debug { "#{self.class} connection receives ClosedError message=#{error.message} code=#{error.code}" }
        connection.close_code = error.code
      ensure
        logger.debug { "#{self.class} connection closed" }
        connection.handle_close
        connection.close
      end
      result || [200, {}, ['Hello World']]
    end
  end
end
