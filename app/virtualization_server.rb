module VirtualizationServer
  class Config < Anyway::Config
    config_name :app # set load path config/app.yml
    attr_config :cookie_secret,
                :libvirt_domain_type,
                :clusters,
                :users,
                :root,
                libvirt_rw: false
  end

  def environment
    ENV.fetch('RACK_ENV') { 'development' }
  end

  def config
    @config ||= Config.new
  end

  def configure
    yield config
  end

  module_function :config, :configure, :environment
end
