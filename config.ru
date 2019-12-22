require_relative 'lib/falcon_patch'
require_relative 'app'

rack_env = ENV['RACK_ENV'] || 'development'
logger = Logger.new(STDOUT)
logger.level = rack_env == 'development' ? :debug : :info

app = Rack::Builder.new do
  use Rack::CommonLogger, logger

  map '/api' do
    run VirtualizationServer::API
  end

  map '/' do
    public_folder = File.join(__dir__, 'public')
    use Rack::Static, urls: %w(/assets /index.html), root: public_folder

    run proc { |_| [404, { 'Content-Type' => 'text/plain' }, ['Not Found']] }
  end

  # Websocket
  map '/cable' do
    use Rack::CommonLogger, logger
    AsyncCable::Server.logger = logger
    DomainEventCable.logger = logger
    run AsyncCable::Server.new(connection_class: DomainEventCable)
  end
end

run app
