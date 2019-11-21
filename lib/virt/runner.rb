require_relative 'loop'

module Virt
  class Runner
    def initialize
      @loop = Virt::Loop.new
    end

    def run
      @thread = Thread.new do
        @loop.run_loop
      end
      @thread.abort_on_exception = true
    end
  end
end
