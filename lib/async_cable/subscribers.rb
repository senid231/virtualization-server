module AsyncCable
  class Subscribers
    def initialize
      @connections = []
      @mutex = Mutex.new
    end

    def add(connection)
      @mutex.synchronize do
        @connections.push(connection)
      end
    end

    def remove(connection)
      @mutex.synchronize do
        @connections.delete(connection)
      end
    end

    def to_a
      @connections
    end
  end
end
