require_relative '../spec_helper'

RSpec.describe VirtualMachine do
  let(:uuid) { '09c1dc30-486e-44f5-82c8-e42e61d34f37' }

  subject { VirtualMachine.new }

  it 'generates a UUID when one is not provided'

  it 'generates a default set of nics when they are not provided'

  it 'generates a default set of disks when they are not provided'

  describe '.from_libvirt' do
    context 'single domain' do
      it 'builds a new VirtualMachine'
    end

    context 'multiple domains' do
      it 'builds an array of new VirtualMachines'
    end
  end
end
