module NeptuneNetworks::Virtualization
  module Models
    class NetworkInterface
      DEFAULT_SOURCE = 'kvm_bridge'.freeze

      attr_reader :uuid, :source, :mac_address

      def initialize(uuid: SecureRandom.uuid, source: DEFAULT_SOURCE, mac_address: generate_mac_address)
        @uuid         = uuid
        @source       = source
        @mac_address  = mac_address
      end

      def to_json(opts = nil)
        as_json.to_json
      end

      def as_json
        {
          uuid: uuid,
          mac_address: mac_address,
          source: source,
        }
      end

      def to_xml
        <<~XML
          <interface type='bridge'>
            <source bridge='#{source}'/>
            <mac address="#{mac_address}"/>
            <model type='virtio'/>
          </interface>
        XML
      end

      private

      def generate_mac_address
        first_octet   = '02'
        extra_octets  = 5.times.map { '%02x' % rand(0..255) }

        [first_octet, extra_octets].flatten.join(':')
      end
    end
  end
end
