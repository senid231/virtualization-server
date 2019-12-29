class DomainEventCable < AsyncCable::Connection
  # Client example js:
  #
  #   var socket = new WebSocket("ws://localhost:4567/cable");
  #   socket.onopen = function(_event) { console.log("WebSocket connected"); };
  #   socket.onerror = function(error) { console.log("WebSocket error", error); };
  #   socket.onclose = function(event) { console.log('WebSocket closed", event.wasClean, event.code, event.reason); };
  #   socket.onmessage = function(event) { console.log("WebSocket data received", JSON.parse(event.data)); };
  #   socket.send( JSON.generate({ hello: 'world' }) );
  #   socket.close( 1000, 'client' );
  #

  def on_open
    logger.debug { "#{to_s}#on_open user_id=#{session['user_id']}" }
    raise AsyncCable::Errors::Unauthorized if current_user.nil?
    logger.debug { "#{to_s}#on_open authorized login=#{current_user.login}" }
  end

  def on_data(data)
    logger.info { "#{to_s}#on_data data=#{data.inspect}" }
    if data[:type] == 'screenshot'
      take_screenshot(data)
    elsif data[:type] == 'ping'
      # ignore
    else
      transmit error: 'invalid type', type: data[:type]
    end
  end

  def on_close
    task = LibvirtAsync::Util.create_task do
      streams.each(&:cancel)
    end
    Async::Task.current.reactor << task
  end

  def to_s
    "#<#{self.class}:0x#{object_id.to_s(16)} @current_user_id=#{current_user&.id}>"
  end

  private

  def take_screenshot(data)
    vm = VirtualMachine.find_by id: data[:id]
    if vm.nil?
      transmit error: 'invalid id', type: 'screenshot', id: data[:id]
      return
    end

    asset_path = "/screenshots/#{vm.id}.pnm"
    file_path = File.join VirtualizationServer.config.root, 'public', asset_path

    stream = nil
    stream = LibvirtAsync::ScreenshotStream.call(vm.hypervisor.connection, vm.adapter.domain) do |success, reason, file|
      if success
        FileUtils.mv file.path, file_path
        transmit file: asset_path, type: 'screenshot', id: data[:id]
      else
        transmit error: reason, type: 'screenshot', id: data[:id]
      end
      streams.delete(stream)
    end

    streams.push(stream)
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by id: session['user_id']
  end

  def session
    env['rack.session']
  end

  def streams
    @streams ||= []
  end
end
