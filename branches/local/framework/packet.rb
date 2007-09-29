# FIXME: not sure whether to complete the connection to an outgoing connection
# here or in Connection class.

module Packet
  # main class which is going to be main worker
  class Reactor
    iattr_accessor :fd_writers, :msg_writers,:msg_reader, :fd_watchlist
    iattr_accessor :listen_sockets
    iattr_accessor :connected_clients
    # following accessor is for external connections, when packet acts as client and connection completion is
    # awaited for those connections.
    iattr_accessor :connection_completion_awaited,:callback_hash


    class << self
      include NbioHelper
      include Socket::Constants

      # this function is going to be replaced with epoll implementation and hence it would be a good
      # to keep this as much modular as possible.
      def run
        @fd_watchlist ||= []
        @callback_hash ||= {}
        @connection_completion_awaited ||= { }
        load_workers
        yield
        loop do
          ready_ios = select(@fd_watchlist,nil,nil,0.005)
          next if ready_ios.blank?
          ready_ios = ready_ios.flatten.compact
          ready_ios.each do |t_sock|
            if t_sock.is_a? UNIXSocket
              handle_internal_messages(t_sock)
            else
              handle_external_messages(t_sock)
            end
          end
        end

      end # end of run method

      def install_signal_handlers
        Signal.trap("INT") { close_socket }
        Signal.trap("TERM") { kill_children }
      end

      def kill_children
        @live_workers.each do |key,value|
          Process.kill("TERM",value.pid)
        end
        exit
      end

      def close_socket
        exit
      end

      # handles external TCP socket messages
      def handle_external_messages(t_sock)
        sock_fd = t_sock.fileno
        if sock_opts = @listen_sockets[sock_fd]
          accept_connection(sock_opts)
        elsif sock_opts = @connection_completion_awaited[sock_fd]
          complete_connection(t_sock,sock_opts)
        else
          parse_request(t_sock)
        end
      end

      def parse_request(t_sock)
        handler_instance = @connected_clients[t_sock.fileno].instance
        begin
          t_data = read_data(t_sock)
          handler_instance.receive_data(t_data) if handler_instance.respond_to?(:receive_data)
        rescue DisconnectError => sock_error
          handler_instance.unbind
          @connected_clients.delete(t_sock.fileno)
          @fd_watchlist.delete(t_sock)
        end
      end

      # handles internal unix socket messages
      def handle_internal_messages(t_sock)
        sock_fd = t_sock.fileno
        messenger = @worker_read_ends[sock_fd].worker_name
        # following information may be sort of redundant, from which worker the data came.
        t_worker = @live_workers[messenger]
        t_data = Marshal.load(read_data(t_sock))
        t_signature = t_data[:callback_signature]
        t_callback = @callback_hash[t_signature]
        t_callback.invoke(t_data)
      end

      # following method completes the connections for sockets, which are connected to outside servers
      def complete_connection(t_sock,sock_opts)
        handler_instance = initialize_server_object(sock_opts[:module])
        @connected_clients[t_sock.fileno] =
          OpenStruct.new({ :client_addr => sock_opts[:sock_addr],:instance => handler_instance,:signature => Guid.new.hexdigest.to_s })
        @connection_completion_awaited.delete(t_sock.fileno)
        sock_opts[:block].call(handler_instance)
        provide_workers(handler_instance,t_sock)
        handler_instance.post_init if handler_instance.respond_to?(:post_init)
        handler_instance.connection_completed if handler_instance.respond_to?(:connection_completed)
      end

      # this function is again going to be replaced with epoll thingy
      def start_server(ip,port,p_module,&block)
        @listen_sockets ||= {}
        @connected_clients ||= {}

        t_socket = Socket.new(AF_INET,SOCK_STREAM,0)
        sockaddr = Socket.sockaddr_in(port.to_i,ip)
        t_socket.bind(sockaddr)
        t_socket.listen(50)
        @listen_sockets[t_socket.fileno] = { :socket => t_socket,:block => block,:module => p_module }
        @fd_watchlist << t_socket
      end

      def accept_connection(sock_opts)
        sock_io = sock_opts[:socket]

        begin
          client_socket,client_sockaddr = sock_io.accept_nonblock
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          puts "not ready yet"
          return
        end
        @fd_watchlist << client_socket
        handler_instance = initialize_server_object(sock_opts[:module])
        provide_workers(handler_instance,client_socket)
        p handler_instance
        sock_opts[:block].call(handler_instance) if sock_opts[:block]
        @connected_clients[client_socket.fileno] =
          OpenStruct.new({ :client_addr => client_sockaddr,:instance => handler_instance,:signature => Guid.new.hexdigest.to_s })
      end

      def provide_workers(handler_instance,t_sock)
        class << handler_instance
          attr_accessor :workers,:connection
          include NbioHelper
          def send_data p_data
            write_data(p_data,connection)
          end

          def send_to_worker(t_worker,options = { })
            t_data = options[:data]
            if t_callback = options[:callback]
              Packet::Reactor.callback_hash[t_callback.signature] = t_callback
              t_worker.send_data(:data => t_data,:function => options[:function],:callback_signature => t_callback.signature)
            else
              t_worker.send_data(:data => t_data,:function => options[:function])
            end
          end
        end
        handler_instance.workers = @live_workers
        handler_instance.connection = t_sock
      end

      def initialize_server_object p_module
        handler =
          if(p_module and p_module.is_a?(Class))
            p_module
          else
            Class.new(Connection) { p_module and include p_module }
          end
        return handler.new
      end

      # method establishes a external connection
      def connect ip,port,p_module
      end

      # method loads workers in new processes
      def load_workers
        @live_workers ||= {}
        @worker_read_ends ||= {}
        worker_root = "#{PACKET_APP}/worker"
        t_workers = Dir["#{worker_root}/**/*.rb"]
        return if t_workers.blank?
        t_workers.each do |b_worker|
          worker_name = File.basename(b_worker,".rb")
          p worker_name.classify
          require worker_name
          worker_klass = Object.const_get(worker_name.classify)
          fork_and_load(worker_klass)
        end
      end

      # method forks given worker file in a new process
      # FIXME: won't work with io workers.
      def fork_and_load(worker_klass)
        # socket from which master process is going to read
        master_read_end,worker_write_end = UNIXSocket.pair(SOCK_STREAM)
        # socket to which master process is going to write
        worker_read_end,master_write_end = UNIXSocket.pair(SOCK_STREAM)

        if worker_klass.worker_type == :io
          worker_read_fd,master_write_fd = UNIXSocket.pair
        end

        if((pid = fork()).nil?)
          p "I am in child now"
          # close file handles which are not required in child
          master_write_end.close
          master_read_end.close
          # master_write_end.close if master_write_end
          worker_klass.start_worker(worker_write_end,worker_read_end,worker_read_fd)
        end
        Process.detach(pid)
        @worker_read_ends[master_read_end.fileno] = OpenStruct.new({:worker_name => worker_klass.worker_name})
        @live_workers[worker_klass.worker_name] = WorkerDelegate.new(master_write_end,pid)
        worker_read_end.close
        worker_write_end.close
        worker_read_fd.close if worker_read_fd
        @fd_watchlist << master_read_end

      end # end of fork_and_load method

    end # end of << self thing

  end # end of Reactor class
end # end of Packet module
