require_relative '../spec_helper'

RSpec.describe Disk do
  let(:uuid) { '1067e21a-f965-4dc5-914d-d481e3ed7af0' }
  let(:size) { 1024 * 1024 * 8 }

  subject { Disk.new(uuid: uuid, size: size) }

  it 'generates a UUID when one is not provided' do
    expect(Disk.new.uuid).to_not be_nil
  end

  it 'sets a default disk size when one is not provided' do
    expect(Disk.new.size).to_not be_nil
  end

  describe '#path' do
    it 'returns the path on disk of the image' do
      expect(subject.path).to eq "/var/lib/libvirt/images/1067e21a-f965-4dc5-914d-d481e3ed7af0.qcow2"
    end
  end

  describe '#to_json' do
    it 'returns a JSON formatted string representing the disk' do
      expected_json = {
        uuid: '1067e21a-f965-4dc5-914d-d481e3ed7af0',
        size: 1024 * 1024 * 8,
      }.to_json

      expect(subject.to_json).to eq expected_json
    end
  end

  describe '#as_json' do
    it 'returns a hash representing the disk' do
      expected_hash = {
        uuid: '1067e21a-f965-4dc5-914d-d481e3ed7af0',
        size: 1024 * 1024 * 8,
      }

      expect(subject.as_json).to eq expected_hash
    end
  end

  describe '#to_xml' do
    it 'returns an XML representation of the disk for libvirt' do
      expected_xml = <<~XML
        <disk type='file' device='disk'>
          <driver name="qemu" type="qcow2"/>
          <source file='/var/lib/libvirt/images/1067e21a-f965-4dc5-914d-d481e3ed7af0.qcow2'/>
          <target dev='hda' bus='ide'/>
        </disk>
      XML

      expect(subject.to_xml).to eq expected_xml
    end
  end
end
