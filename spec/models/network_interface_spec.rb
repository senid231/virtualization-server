require_relative '../spec_helper'

RSpec.describe NetworkInterface do
  let(:uuid)        { 'e83e33df-bfa9-457a-af5d-563f91dc6477' }
  let(:mac_address) { '02:6f:cc:f3:04:81' }

  subject { NetworkInterface.new(uuid: uuid, mac_address: mac_address) }

  it 'generates a UUID when one is not provided' do
    expect(NetworkInterface.new.uuid).to_not be_nil
  end

  it 'generates a default source when one is not provided' do
    expect(NetworkInterface.new.source).to eq 'kvm_bridge'
  end

  it 'generates a mac address when one is not provided' do
    expect(NetworkInterface.new.mac_address).to_not be_nil
  end

  describe '#to_json' do
    it 'returns a JSON formatted string representing the NIC' do
      expected_json = {
        uuid: 'e83e33df-bfa9-457a-af5d-563f91dc6477',
        source: 'kvm_bridge',
        mac_address: '02:6f:cc:f3:04:81',
      }.to_json

      expect(subject.to_json).to eq expected_json
    end
  end

  describe '#as_json' do
    it 'returns a hash representing the NIC' do
      expected_hash = {
        uuid: 'e83e33df-bfa9-457a-af5d-563f91dc6477',
        source: 'kvm_bridge',
        mac_address: '02:6f:cc:f3:04:81',
      }

      expect(subject.as_json).to eq expected_hash
    end
  end

  describe '#to_xml' do
    it 'returns an XML representation of the NIC for libvirt' do
      expected_xml = <<~XML
        <interface type='bridge'>
          <source bridge='kvm_bridge'/>
          <mac address="02:6f:cc:f3:04:81"/>
          <model type='virtio'/>
        </interface>
      XML

      expect(subject.to_xml).to eq expected_xml
    end
  end
end
