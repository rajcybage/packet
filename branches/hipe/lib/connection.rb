# FIMXE: following class must modify the fd_watchlist thats being monitored by
# main eventloop.

module Packet
  class Connection
    # method gets called when connection to external server is completed
    def connection_completed

    end

    # method gets called when external client is disconnected
    def unbind

    end

    # method gets called just at the beginning of initializing things.
    def post_init

    end

    def send_data

    end

    def ask_worker

    end

    def receive_data

    end
  end # end of class Connection
end # end of module Packet
