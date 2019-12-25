require 'async/websocket/connection'

module AsyncCable
  class Connection < Async::WebSocket::Connection
    class_attribute :subscribers, instance_writer: false
    class_attribute :logger, instance_writer: false, default: Logger.new('/dev/null')

    # Broadcast data to all clients (except filtered out when filter provided)
    # @param data [Hash] - data to broadcast (required)
    # @param filter [Proc<AsyncCable::Connection>] - proc to filter connections.
    def self.broadcast(data, filter: nil)
      logger.debug { "#{name}.broadcast data=#{data.inspect}" }

      list = subscribers.to_a
      list = list.select(&filter) if filter

      list.each { |_, conn| conn.transmit(data) }
      nil
    end

    attr_reader :env
    attr_accessor :close_code

    # to override
    def on_open
    end

    # to override
    def on_data(data)
    end

    # to override
    def on_close
    end

    # Transmits data to client
    def transmit(data)
      logger.debug { "#{self.class}#transmit data=#{data.inspect}" }

      write(data)
      flush
    end

    def handle_command(data)
      logger.debug { "#{self.class}#handle_command data=#{data.inspect}" }
      on_data(data)
    end

    def handle_open(env)
      @env = env
      subscribers.add(self)
      on_open
    end

    def handle_close
      self.close_code ||= Protocol::WebSocket::Error::NO_ERROR
      logger.debug { "#{self.class}#handle_close clean_close?=#{clean_close?} close_code=#{close_code}" }
      subscribers.remove(self)
      on_close
    end

    def clean_close?
      close_code == Protocol::WebSocket::Error::NO_ERROR
    end
  end
end
