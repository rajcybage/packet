# class implements general worker

module Packet
  class Worker
    include NbioHelper

    # fd_readers: IO handlers from which fd will be retrieved
    # msg_writers: IO Unix handlers to which responses will be written
    # msg_readers: IO Unix handlers from which requests will be retrieved.
    iattr_accessor :fd_reader,:msg_writer,:msg_reader,:external_sockets,:fd_watchlist,:worker_name
    attr_accessor :worker_started
    attr_accessor :connection_completion_awaited
    attr_accessor :connections

    # method initializes the eventloop for the worker
    def self.start_worker(*args)
      @worker_running = false
      @msg_writer,@msg_reader = *args
      @fd_watchlist ||= []
      @fd_watchlist << @msg_reader
      @external_sockets ||= {}
      t_instance = new
      t_instance.worker_init
      # start event loop if worker_init is called.
      t_instance.start_event_loop # if @worker_started
    end

    # initialize couple of local variables.
    def initialize
      @worker_started = false
      @connection_completion_awaited ||= {}
      # completed connections.
      @connections ||= {}
      # sockets on which this worker is listening.
      @listen_sockets ||= {}
    end

    def start_event_loop
      loop do
        ready_ios = select(fd_watchlist,nil,nil,0.005)
        next if ready_ios.blank?
        ready_ios = ready_ios.flatten.compact
        ready_ios.each do |t_sock|
          if t_sock.is_a? UNIXSocket
            handle_internal_request(t_sock)
          else
            handle_external_request(t_sock)
          end
        end
      end
    end

    def connect ip,port,t_module,&block
      t_socket = Socket.new(Socket::AF_INET,Socket::SOCK_STREAM,0)
      t_sock_addr = Socket.sockaddr_in(port.to_i,ip)
      @connection_completion_awaited[t_socket.fileno] =
        { :sock_addr => t_sock_addr, :module => t_module, :block => block }
      begin
        t_socket.connect_nonblock(t_sock_addr)
        immediate_complete(t_socket,t_sock_addr,t_module,&block)
      rescue Errno::EINPROGRESS
        fd_watchlist << t_socket
      end
    end

    def start_server(ip,port,t_module,&block)
      t_socket = Socket.new(AF_INET,SOCK_STREAM,0)
      sockaddr = Socket.sockaddr_in(port.to_i,ip)
      t_socket.bind(sockaddr)
      t_socket.listen(50)
      @listen_sockets[t_socket.fileno] = { :socket => t_socket,:block => block,:module => p_module }
      fd_watchlist << t_socket
    end

    # method completes a connection, when connection is completed immediately.
    def immediate_complete(p_socket,p_sock_addr,p_module,&block)
      handler_instance = initialize_class_object(p_module)
      block.call(handler_instance)
      decorate_connection(handler_instance,:sock_addr => p_sock_addr,:connection => p_socket,:signature => Guid.new.hexdigest.to_s)
      @connection_completion_awaited.delete(p_socket.fileno)
      # not sure here if using just instance is enough.
      @connections[p_socket.fileno] = OpenStruct.new(:instance => handler_instance)
      fd_watchlist << p_socket
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
      sock_opts[:block].call(handler_instance) if sock_opts[:block]
      decorate_connection(handler_instance,:sock_addr => client_sockaddr,:connection => client_socket,:signature => Guid.new.hexdigest.to_s )
      @connection[client_socket.fileno] = OpenStruct.new(:instance => handler_instance)
    end

    # method completes connection,
    def just_complete_connection(p_sock,sock_opts)
    end

    def decorate_connection(handler_instance,sock_opts)
      class << handler_instance
        include NbioHelper
        attr_accessor :connection,:sock_addr,:signature
        def send_data(p_data)
          write_data(p_data,connection)
        end
      end
      handler_instance.connection = sock_opts[:connection]
      handler_instance.sock_addr = sock_opts[:sock_addr]
      handler_instance.signature = sock_opts[:signature]
      handler_instance.post_init if handler_instance.respond_to?(:post_init)
      handler_instance.connection_completed if handler_instance.respond_to?(:connection_completed)
    end

    def send_data p_data
      write_data(Marshal.dump(p_data),msg_writer)
    end

    # method handles internal requests from internal sockets
    def handle_internal_request(t_sock)
      t_data = Marshal.load(read_data(t_sock))
      # worker should extract data, function, and then invoke the callback if asked.
      receive_internal_data(t_data)
    end

    # method handles requests from external sockets
    def handle_external_request(t_sock)
      if t_client = @listen_sockets[t_sock.fileno]
        accept_connection(t_client)
      elsif sock_opts = @connection_completion_awaited[t_sock.fileno]
        just_complete_connection(t_sock,sock_opts)
      else
        t_data = read_data(t_sock)
        receive_data(t_data)
      end
    end

    # method receives data from internal UNIX Sockets
    def receive_internal_data p_data
      raise "Not implemented for worker"
    end

    # method receives data from external TCP Sockets
    def receive_data p_data
      raise "Not implemented for worker"
    end

    # method checks if client has asked to execute a internal function
    def invoke_internal_function
      raise "Not implemented for worker"
    end

    # message returns data to parent process, using UNIX Sockets
    def invoke_callback
      raise "Not implemented for worker"
    end

    def initialize_class_object p_module
      handler =
        if(p_module and p_module.is_a?(Class))
          p_module
        else
          Class.new(WorkerConnection) { p_module and include p_module }
        end
      return handler.new
    end

  end
end

