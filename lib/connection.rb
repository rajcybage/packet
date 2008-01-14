# FIMXE: following class must modify the fd_watchlist thats being monitored by
# main eventloop.

module Packet
  module Connection
    attr_accessor :outbound_data 
    
    def send_data p_data
      begin
        leftover = write_once(p_data,connection)
        @outbound_data << leftover if leftover && !leftover.empty?
      rescue DisconnectError => sock_error
        close_connection
      end
    end

    def invoke_init
      @initialized = true
      @outbound_data = []
      post_init if respond_to?(:post_init)
    end

    def close_connection
      unbind if respond_to?(:unbind)
      reactor.remove_connection(connection)
    end

    def close_connection_after_writing
      connection.flush
      close_connection
    end

    def send_object p_object
      dump_object(p_object,connection)
    end
  end # end of class Connection
end # end of module Packet
