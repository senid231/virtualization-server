module NeptuneNetworks::Virtualization
  module Models
    class Disk
      STORAGE_LOCATION = '/var/lib/libvirt/images'.freeze

      attr_reader :uuid, :size

      def initialize(uuid: SecureRandom.uuid, size: 1024 * 1024 * 10)
        @uuid = uuid
        @size = size
      end

      def path
        "#{STORAGE_LOCATION}/#{uuid}.qcow2"
      end

      def to_json(opts = nil)
        as_json.to_json
      end

      def as_json
        {
          uuid: uuid,
          size: size,
        }
      end

      def to_xml
        <<~XML
          <disk type='file' device='disk'>
            <driver name="qemu" type="qcow2"/>
            <source file='#{path}'/>
            <target dev='hda' bus='ide'/>
          </disk>
        XML
      end
    end
  end
end
