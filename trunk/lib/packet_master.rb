# FIXME: Some code is duplicated between worker class and this Reactor class, that can be fixed
# with help of creation of Connection class and enabling automatic inheritance of that class and
# mixing in of methods from that class.
module Packet
  class Reactor
    include Core
    attr_accessor :fd_writers, :msg_writers,:msg_reader
    attr_accessor :live_workers
    after_connection :provide_workers

    def self.run
      master_reactor_instance = new
      yield(master_reactor_instance)
      master_reactor_instance.load_workers
      master_reactor_instance.start_reactor
    end # end of run method

    def provide_workers(handler_instance,t_sock)
      class << handler_instance
        extend Forwardable
        attr_accessor :workers,:connection,:reactor, :initialized,:signature
        include NbioHelper
        def send_data p_data
          begin
            write_data(p_data,connection)
          rescue Errno::EPIPE
            # probably a callback, when there is a error in writing to the socket
          end
        end
        def invoke_init
          @initialized = true
          post_init
        end

        def close_connection
          unbind
          reactor.connections.delete(connection.fileno)
          connection.close
        end

        def close_connection_after_writing
          connection.flush
          unbind
          reactor.connections.delete(connection.fileno)
          connection.close
        end

        def ask_worker(*args)
          worker_name = args.shift
          data_options = *args
          data_options[:client_signature] = connection.fileno
          workers[worker_name].send_request(data_options)
        end

        def send_object p_object
          dump_object(p_object,connection)
        end
        def_delegators :@reactor, :start_server, :connect, :add_periodic_timer, :add_timer, :cancel_timer,:reconnect
      end
      handler_instance.workers = @live_workers
      handler_instance.connection = t_sock
      handler_instance.reactor = self
    end

    # FIXME: right now, each worker is tied to its connection and this can be problematic
    # what if a worker wants to return results in a async manner
    def handle_internal_messages(t_sock)
      sock_fd = t_sock.fileno
      worker_instance = @live_workers[sock_fd]
      begin
        raw_data = read_data(t_sock)
        # t_data = Marshal.load(raw_data)
        worker_instance.receive_data(raw_data) if worker_instance.respond_to?(:receive_data)
      rescue DisconnectError => sock_error
        read_ios.delete(t_sock)
      end
    end

    # method loads workers in new processes
    def load_workers
      @live_workers = DoubleKeyedHash.new
      if defined?(WORKER_ROOT)
        worker_root = WORKER_ROOT
      else
        worker_root = "#{PACKET_APP}/worker"
      end
      t_workers = Dir["#{worker_root}/**/*.rb"]
      return if t_workers.blank?
      t_workers.each do |b_worker|
        worker_name = File.basename(b_worker,".rb")
        require worker_name
        worker_klass = Object.const_get(worker_name.classify)
        fork_and_load(worker_klass)
      end

      # FIXME: easiest and yet perhaps a bit ugly
      @live_workers.each do |key,worker_instance|
        worker_instance.workers = @live_workers
      end
    end

    # method forks given worker file in a new process
    def fork_and_load(worker_klass)
      t_worker_name = worker_klass.worker_name
      worker_pimp = worker_klass.worker_proxy.to_s

      # socket from which master process is going to read
      master_read_end,worker_write_end = UNIXSocket.pair(Socket::SOCK_STREAM)
      # socket to which master process is going to write
      worker_read_end,master_write_end = UNIXSocket.pair(Socket::SOCK_STREAM)

      worker_read_fd,master_write_fd = UNIXSocket.pair
      if((pid = fork()).nil?)
        # close file handles which are not required in child
        $0 = "ruby #{worker_klass.worker_name}"
        master_write_end.close
        master_read_end.close
        master_write_fd.close
        # master_write_end.close if master_write_end
        worker_klass.start_worker(:write_end => worker_write_end,:read_end => worker_read_end,:read_fd => worker_read_fd)
      end
      Process.detach(pid)
      # if no pimp exists for the given class then we should create a pimp class for the worker
      # meta programmatically.
      unless worker_pimp.blank?
        require worker_pimp
        pimp_klass = Object.const_get(worker_pimp.classify)
        @live_workers[t_worker_name,master_read_end.fileno] = pimp_klass.new(master_write_end,pid,self)
      else
        @live_workers[t_worker_name,master_read_end.fileno] = Packet::MetaPimp.new(master_write_end,pid,self)
      end

      worker_read_end.close
      worker_write_end.close
      worker_read_fd.close
      read_ios << master_read_end
    end # end of fork_and_load method

  end # end of Reactor class
end # end of Packet module
