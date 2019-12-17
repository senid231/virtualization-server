require 'yaml'
require 'lib/hypervisor'

puts Libvirt::version()

if ENV['LIBVIRT_DEBUG'].present?
  LibvirtAsync.use_logger!
  LibvirtAsync.logger.level = :debug
end

LibvirtAsync.register_implementations!

clusters = YAML.load_file(File.join(__dir__, '..', 'cluster.yml'))
Hypervisor.load_storage(clusters)

Hypervisor.all.each do |hv|
  puts "Hypervisor #{hv.id} #{hv.name} #{hv.uri}"
end
