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
  end

  def on_data(data)
    logger.info { "#{self.class}#on_data data=#{data.inspect}" }
    action = data[:action]
    if data[:action] == 'screenshot'
      screenshot_action(data[:payload])
    else
      transmit(error: "action #{action} is invalid", status: 400)
    end
  end

  private

  def screenshot_action(payload)
    vm_id = payload[:vm_id]
    vm = VirtualMachine.find_by(id: vm_id)
    if vm.nil?
      transmit(error: "vm not found vm_id=#{vm_id}", status: 400)
    else
      transmit(action: 'screenshot', response: vm.screenshot)
    end
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by id: session['user_id']
  end

  def session
    env['rack.session']
  end
end
