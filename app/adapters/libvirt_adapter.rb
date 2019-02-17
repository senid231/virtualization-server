module LibvirtAdapter
  CLIENT = Libvirt::open('qemu:///session')
end
