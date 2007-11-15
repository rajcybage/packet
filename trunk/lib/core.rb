# FIXME: timer implementation can be optimized
module Packet
  module Core
    def self.included(base_klass)
      base_klass.extend(ClassMethods)
      base_klass.instance_eval do
        # iattr_accessor :connection_callbacks
        @@connection_callbacks ||= {}
        cattr_accessor :connection_callbacks
        attr_accessor :read_ios, :write_ios, :listen_sockets
        attr_accessor :connection_completion_awaited
        attr_accessor :connections
        include CommonMethods
      end
    end

    module ClassMethods
      def after_connection p_method
        connection_callbacks[:after_connection] ||= []
        connection_callbacks[:after_connection] << p_method
      end

      def after_unbind p_method
        connection_callbacks[:after_unbind] ||= []
        connection_callbacks[:after_unbind] << p_method
      end

      def before_unbind p_method
        connection_callbacks[:before_unbind] ||= []
        connection_callbacks[:before_unbind] << p_method
      end
    end # end of module#ClassMethods

    module CommonMethods
      include NbioHelper
      # method
      def connect(ip,port,t_module,&block)
        t_socket = Socket.new(Socket::AF_INET,Socket::SOCK_STREAM,0)
        t_sock_addr = Socket.sockaddr_in(port,ip)
        t_socket.setsockopt(Socket::IPPROTO_TCP,Socket::TCP_NODELAY,1)

        connection_completion_awaited[t_socket.fileno] =
          { :sock_addr => t_sock_addr, :module => t_module,:block => block }
        begin
          t_socket.connect_nonblock(t_sock_addr)
          immediate_complete(t_socket,t_sock_addr,t_module,&block)
        rescue Errno::EINPROGRESS
          write_ios << t_socket
        end
      end

      def reconnect(server,port,handler)
        raise "invalid handler" unless handler.respond_to?(:connection_completed)
        return handler if connections.keys.include?(handler.connection.fileno)
        connect(server,port,handler)
      end

      def immediate_complete(t_socket,sock_addr,t_module,&block)
        read_ios << t_socket
        write_ios.delete(t_socket)
        decorate_handler(t_socket,true,sock_addr,t_module,&block)
        connection_completion_awaited.delete(t_socket.fileno)
      end

      def accept_connection(sock_opts)
        sock_io = sock_opts[:socket]

        begin
          client_socket,client_sockaddr = sock_io.accept_nonblock
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          puts "not ready yet"
          return
        end
        read_ios << client_socket
        decorate_handler(client_socket,true,client_sockaddr,sock_opts[:module],&sock_opts[:block])
      end

      def complete_connection(t_sock,sock_opts)
        actually_connected = true
        begin
          t_sock.connect_nonblock(sock_opts[:sock_addr])
        rescue Errno::EISCONN
          puts "Socket already connected"
        rescue Errno::ECONNREFUSED
          actually_connected = false
        end

        read_ios << t_sock if actually_connected
        write_ios.delete(t_sock)
        decorate_handler(t_sock,actually_connected,sock_opts[:sock_addr],sock_opts[:module],&sock_opts[:block])
        connection_completion_awaited.delete(t_sock.fileno)
      end

      def close_connection
      end

      def socket_really_connected?(t_sock)
        begin
          t_data = read_data(t_sock)
          return true
        rescue DisconnectError
          return false
        end
      end

      # method opens a socket for listening
      def start_server(ip,port,t_module,&block)
        t_socket = Socket.new(Socket::AF_INET,Socket::SOCK_STREAM,0)
        t_socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,true)
        sockaddr = Socket.sockaddr_in(port.to_i,ip)
        t_socket.bind(sockaddr)
        t_socket.listen(50)
        t_socket.setsockopt(Socket::IPPROTO_TCP,Socket::TCP_NODELAY,1)
        listen_sockets[t_socket.fileno] = { :socket => t_socket,:block => block,:module => t_module }
        @read_ios << t_socket
      end

      # method starts event loop in the process
      def start_reactor
        Signal.trap("TERM") { terminate_me }
        Signal.trap("INT") { shutdown }
        loop do
          check_for_timer_events
          ready_fds = select(@read_ios,@write_ios,nil,0.005)
          next if ready_fds.blank?
          ready_fds = ready_fds.flatten.compact
          ready_fds.each do |t_sock|
            if t_sock.is_a? UNIXSocket
              handle_internal_messages(t_sock)
            else
              handle_external_messages(t_sock)
            end
          end
        end
      end

      def terminate_me
        exit
      end

      def shutdown
        exit
      end

      def handle_internal_messages(t_sock)
        raise "Method should be implemented by concerned classes"
      end

      def handle_external_messages(t_sock)
        sock_fd = t_sock.fileno
        if sock_opts = listen_sockets[sock_fd]
          accept_connection(sock_opts)
        elsif extern_opts = connection_completion_awaited[sock_fd]
          complete_connection(t_sock,extern_opts)
        else
          read_external_socket(t_sock)
        end
      end

      def read_external_socket(t_sock)
        handler_instance = connections[t_sock.fileno].instance
        begin
          t_data = read_data(t_sock)
          handler_instance.receive_data(t_data) if handler_instance.respond_to?(:receive_data)
        rescue DisconnectError => sock_error
          handler_instance.unbind
          connections.delete(t_sock.fileno)
          read_ios.delete(t_sock)
        end
      end

      def add_periodic_timer(interval,&block)
        t_timer = PeriodicEvent.new(interval,&block)
        @timer_hash[t_timer.timer_signature] = t_timer
        return t_timer
      end

      def add_timer(elapsed_time,&block)
        t_timer = Event.new(elapsed_time,&block)
        @timer_hash[t_timer.timer_signature] = t_timer
        return t_timer
      end

      def cancel_timer(t_timer)
        @timer_hash.delete(t_timer.timer_signature)
      end

      def initialize
        @read_ios ||= []
        @write_ios ||= []
        @connection_completion_awaited ||= {}
        @connections ||= {}
        @listen_sockets ||= {}

        @timer_hash ||= {}
      end

      def check_for_timer_events
        @timer_hash.each do |key,timer|
          if timer.run_now?
            #begin
            timer.run
            #             rescue
            #               @timer_hash.delete(key)
            #             end
            @timer_hash.delete(key) if !timer.respond_to?(:interval)
          end
        end
      end

      def initialize_handler(p_module)
        return p_module if(!p_module.is_a?(Class) and !p_module.is_a?(Module))
        handler =
          if(p_module and p_module.is_a?(Class))
            p_module
          else
            Class.new(Connection) { p_module and include p_module }
          end
        return handler.new
      end

      def decorate_handler(t_socket,actually_connected,sock_addr,t_module,&block)
        handler_instance = initialize_handler(t_module)
        connection_callbacks[:after_connection].each { |t_callback| self.send(t_callback,handler_instance,t_socket)}
        handler_instance.invoke_init unless handler_instance.initialized
        unless actually_connected
          handler_instance.unbind if handler_instance.respond_to?(:unbind)
          return
        end
        t_signature = Guid.hexdigest
        handler_instance.signature = t_signature
        connections[t_socket.fileno] =
          OpenStruct.new( :socket => t_socket, :instance => handler_instance, :signature => t_signature,:sock_addr => sock_addr)
        block.call(handler_instance) if block
        handler_instance.connection_completed if handler_instance.respond_to?(:connection_completed)
      end

    end # end of module#CommonMethods
  end #end of module#Core
end #end of module#Packet
