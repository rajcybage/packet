module Packet
  module NbioHelper
    # nonblocking method of reading data
    # when method returns nil it probably means that client diconnected
    def read_data(t_sock)
      sock_data = nil
      begin
        while(sock_data = t_sock.read_nonblock(1023)); end
      rescue Errno::EAGAIN
        return sock_data
      rescue
        puts $!
        puts $!.backtrace
        return sock_data
      end
    end

    def send_data(p_data,p_sock)
      t_data = p_data.dup.to_s
      t_length = t_data.length
      loop do
        begin
          written_length = t_sock.write_nonblock(t_data)
        rescue Errno::EAGAIN
          break
        end
        break if written_length >= t_length
        t_data = t_data[written_length..-1]
        break if t_data.empty?
        t_length = t_data.length
      end
    end
  end
end
