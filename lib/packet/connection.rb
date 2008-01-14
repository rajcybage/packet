# FIMXE: following class must modify the fd_watchlist thats being monitored by
# main eventloop.

module Packet
  module Connection
    attr_accessor :outbound_data,:connection_live

    def send_data p_data
      @outbound_data << p_data
      write_and_schedule
    end

    def invoke_init
      @initialized = true
      @connection_live = true
      @outbound_data = []
      post_init if respond_to?(:post_init)
    end

    def close_connection
      unbind if respond_to?(:unbind)
      reactor.cancel_write(connection)
      reactor.remove_connection(connection)
    end

    def close_connection_after_writing
      connection.flush
      close_connection
    end

    def send_object p_object
      dump_object(p_object,connection)
    end

    # write the data in socket buffer and schedule the thing
    def write_and_schedule
      @outbound_data.each_with_index do |t_data,index|
        begin
          leftover = write_once(t_data,connection)
        rescue DisconnectError => e
          close_connection
          @connection_live = false
          break
        end

        if leftover.empty?
          @outbound_data.delete_at(index)
        else
          @outbound_data[index] = leftover
          reactor.schedule_write(connection)
          break
        end
      end
    end
  end # end of class Connection
end # end of module Packet
