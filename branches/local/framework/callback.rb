# class implements a simple callback mechanism for invoking callbacks
module Packet
  class Callback
    attr_accessor :signature,:stored_proc
    def initialize(&block)
      @signature = Guid.new.hexdigest.to_s
      @stored_proc = block
    end
    
    def invoke(*args)
      @stored_proc.call(*args)
    end
  end
end
