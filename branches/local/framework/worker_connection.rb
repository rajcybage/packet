module Packet
  class WorkerConnection
    # calls when data is received
    def receive_data p_data
    end

    # called when client disconnects
    def unbind
    end

    # called initially
    def post_init
    end

    # connection_completed
    def connection_completed
    end
  end
end
