# initialize loop

puts 'Async mode on.'
require 'lib/virt/async_loop'
VIRT_RUNNER = Virt::AsyncLoop.run

# puts 'Async mode off.'
# require 'lib/virt/loop'
# VIRT_RUNNER = Virt::Loop.run

clusters = YAML.load_file(File.join(__dir__, '..', 'config', 'cluster.yml'))
Hypervisor.load_storage(clusters)

Hypervisor.all.each do |hv|
  puts "Hypervisor #{hv.id} #{hv.name} #{hv.uri}"
end
