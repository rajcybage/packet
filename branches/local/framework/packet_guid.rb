module Packet
  class Guid
    @@random_device = nil
    def initialize
      @@random_device = File.open("/dev/random") if !@@random_device
      @bytes = @@random_device.read(16)
    end

    def hexdigest
      @bytes.unpack("h*")[0]
    end

    def to_s
      @bytes.unpack("h8 h4 h4 h4 h12").join "-"
    end

    def inspect
      to_s
    end

    def raw
      @bytes
    end

    def self.from_s(s)
      raise ArgumentError, "Invalid GUID hexstring" unless
        s =~ /\A[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}\z/i
      guid = Guid.allocate
      guid.instance_eval { @bytes = [s.gsub(/[^0-9a-f]+/i, '')].pack "h*" }
      guid
    end

    def self.from_raw(bytes)
      raise ArgumentError, "Invalid GUID raw bytes, length must be 16 bytes" unless
        bytes.length == 16
      guid = Guid.allocate
      guid.instance_eval { @bytes = bytes }
      guid
    end

    def ==(other)
      @bytes == other.raw
    end
  end
end
