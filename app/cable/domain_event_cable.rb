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
    logger.debug { "#{self.class}#on_open user_id=#{session['user_id']}" }
    raise AsyncCable::Errors::Unauthorized if current_user.nil?
    logger.debug { "#{self.class}#on_open authorized login=#{current_user.login}" }
    @cancel_procs = []
  end

  def on_data(data)
    logger.info { "#{self.class}#on_data data=#{data.inspect}" }
    if data[:type] =='screenshot'
      take_screenshot(data)
    else
      transmit error: 'invalid type', type: data[:type]
    end
  end

  def on_close
    @cancel_procs.each(&:call)
  end

  private

  def take_screenshot(data)
    vm = VirtualMachine.find_by id: data[:id]
    if vm.nil?
      transmit error: 'invalid id', type: data[:type]
      return
    end

    asset_path = "/screenshots/#{vm.id}.png"
    os_path = File.join(VirtualizationServer.config.root, 'public', asset_path)
    cancel_proc = nil
    cancel_proc = vm.take_screenshot(os_path) do |success, _filename, reason|
      @cancel_procs.delete(cancel_proc)
      payload = data.slice(:type)
      payload.merge! success ? { file: asset_path } : { error: reason }
      transmit(payload)
    end
    @cancel_procs.push(cancel_proc)
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by id: session['user_id']
  end

  def session
    env['rack.session']
  end
end
