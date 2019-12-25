module AsyncCable
  module Errors
    class Error < StandardError
    end

    class Unauthorized < Error
      def initialize
        super('unauthorized')
      end

      def code
        1401
      end
    end
  end
end
