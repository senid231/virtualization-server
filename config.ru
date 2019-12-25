require 'rack/contrib'
require_relative 'patches/falcon'
require_relative 'app'
require_relative 'patches/sinja'
require_relative 'lib/vm_screenshot_controller'

rack_env = ENV['RACK_ENV'] || 'development'
is_rack_env_development = rack_env == 'development'
logger = Logger.new(STDOUT)
logger.level = is_rack_env_development ? :debug : :info
AsyncCable::Server.logger = logger
DomainEventCable.logger = logger
VMScreenshotController.logger = logger

app = Rack::Builder.new do
  use Rack::CommonLogger, logger

  use Rack::Session::Cookie,
      key: '_virtualization.server',
      secret: VirtualizationServer.config.cookie_secret

  use Rack::Protection::SessionHijacking

  map '/api' do
    run VirtualizationServer::API
  end

  map '/vm_screenshot' do
    run proc { |env| VMScreenshotController.new(env).call }
  end

  map '/' do
    public_folder = File.join(__dir__, 'public')
    use Rack::Static, urls: %w(/assets /index.html), root: public_folder

    run proc { |_| [404, { 'Content-Type' => 'text/plain' }, ['Not Found']] }
  end if is_rack_env_development

  # Websocket
  map '/cable' do
    run AsyncCable::Server.new(connection_class: DomainEventCable)
  end
end

run app
