class LoggerMutex
  attr_reader :mutex

  def initialize
    @mutex = Mutex.new
  end

  def synchronize
    dbg 'acquiring lock'
    @mutex.synchronize do
      dbg 'locked'
      yield
    end
    dbg 'unlocked'
  end

  private

  def dbg(msg)
    meth_name = caller.first.match(/`(.+)'/)[2]
    AppLogger.debug("0x#{object_id.to_s(16)}") { "#{self.class}::#{meth_name} #{msg}" }
  end
end
