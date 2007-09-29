module Packet
  class WorkerDelegate
    include NbioHelper
    attr_accessor :lifeline,:pid,:signature
    attr_accessor :fd_write_end
    def initialize(lifeline_socket,worker_pid)
      @lifeline = lifeline_socket
      @pid = worker_pid
      @signature = Guid.new.hexdigest.to_s
    end

    def send_data p_data
      write_data(Marshal.dump(p_data),@lifeline)
    end

    def send_fd sock_fd
      @fd_write_end.send_io(sock_fd)
    end
    alias_method :do_work, :send_data
  end
end
