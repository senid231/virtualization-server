require 'yaml'
require 'lib/hypervisor'
require 'lib/virt/runner'

puts Libvirt::version()

# VIRT_RUNNER = Virt::Runner.new.run
# clusters = YAML.load_file(File.join(__dir__, '..', 'cluster.yml'))
# Hypervisor.load_storage(clusters)
#
# Hypervisor.all.each do |hv|
#   puts "Hypervisor #{hv.id} #{hv.name} #{hv.uri}"
# end
