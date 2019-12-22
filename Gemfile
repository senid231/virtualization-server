source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.0'

gem 'dotenv'
gem 'sinatra'
gem 'ruby-libvirt'
gem 'pry'
gem 'sinja'
gem 'jsonapi-serializers'
gem 'activesupport'

# Async libvirt event api implementation
# https://github.com/senid231/libvirt_async
gem 'libvirt_async', '~> 0.1'

# Async web server
# https://github.com/socketry/falcon
gem 'falcon'

# Async websocket implementation
# https://github.com/socketry/async-websocket
gem 'async-websocket'

group :development do
  gem 'byebug'
end

group :test do
  gem 'rspec'
end

