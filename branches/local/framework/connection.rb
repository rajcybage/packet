# FIMXE: following class must modify the fd_watchlist thats being monitored by
# main eventloop.

module Packet
  class Connection
    class << self
      def connect(ip,port,t_module,&block)
        t_socket = Socket.new(Socket::AF_INET,Socket::SOCK_STREAM,0)
        t_sock_addr = Socket.sockaddr_in(port,ip)
        Reactor.connection_completion_awaited[t_socket.fileno] = { :sock_addr => t_sock_addr, :module => t_module,:block => block }
        begin
          t_socket.connect_nonblock(t_sock_addr)
          immediate_complete(t_socket,t_sock_addr,t_module,&block)
        rescue Errno::EINPROGRESS
          Reactor.fd_watchlist << t_sock
        end

        # add the connected socket to list of file descriptors which main
        # thread is watching.
      end # end of method connect

      def immediate_complete(t_sock,t_sock_addr,t_module,&block)
        Reactor.fd_watchlist << t_sock
        handler_instance = initialize_class_object(t_module)
        Reactor.connected_clients[t_sock.fileno] =
          OpenStruct.new(:client_addr => t_sock_addr,:instance => handler_instance, :signature => Guid.new.hexdigest.to_s )
        Reactor.connection_completion_awaited.delete(t_sock.fileno)

        # invoke the block if client has provided
        block.call(handler_instance) if block

        handler_instance.post_init if handler_instance.respond_to?(:post_init)
        handler_instance.connection_completed if handler_instance.respond_to?(:connection_completed)
      end # end of method connection_completed

      # following method initializes object for the given class
      def initialize_class_object p_module
        handler =
          if(p_module and p_module.is_a?(Class))
            p_module
          else
            Class.new(Connection) { p_module and include p_module }
          end
        return handler.new
      end # end of method initialize_class_object
    end # end of class << self

    # method gets called when connection to external server is completed
    def connection_completed

    end

    # method gets called when external client is disconnected
    def unbind

    end

    # method gets called just at the beginning of initializing things.
    def post_init

    end
  end # end of class Connection
end # end of module Packet
