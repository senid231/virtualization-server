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
    logger.info { "#{self.class}#on_data ignored data=#{data.inspect}" }
  end

  private

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by id: session['user_id']
  end

  def session
    env['rack.session']
  end
end
