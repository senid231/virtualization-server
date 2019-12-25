class VMScreenshotController
  class_attribute :logger, instance_writer: false, default: Logger.new('/dev/null')

  attr_reader :env, :params, :session

  def initialize(env)
    @env = env
    @session = env['rack.session']
    @params = Rack::Utils.parse_nested_query(env['QUERY_STRING']).symbolize_keys
  end

  def call
    logger.debug { "#{self.class}#call params=#{params} user_id=#{session['user_id']}" }

    user = User.find_by id: session['user_id']
    return not_authorized if user.nil?

    vm = VirtualMachine.find_by id: params[:id]
    return not_found if vm.nil?

    headers = {
        'Content-Type' => 'image/png',
        'X-Accel-Redirect' => "vm_screenshot_#{vm.id}",
        'Content-Disposition' => "attachment; filename=\"vm_screenshot_#{vm.id}.png\""
    }
    [200, headers, []]
  end

  private

  def not_authorized
    [401, { 'Content-Type' => 'text/plain' }, ['unauthorized']]
  end

  def not_found
    [404, { 'Content-Type' => 'text/plain' }, ['not found']]
  end
end
