module Packet
  module NbioHelper
    # nonblocking method of reading data
    # when method returns nil it probably means that client diconnected
    def read_data(t_sock)
      sock_data = ""
      begin
        while(sock_data << t_sock.read_nonblock(1023)); end
      rescue Errno::EAGAIN
        return sock_data
      rescue
        raise DisconnectError.new(t_sock)
      end
    end

    def write_data(p_data,p_sock)
      return unless p_data
      if p_data.is_a? Fixnum
        t_data = p_data.to_s
      else
        t_data = p_data.dup.to_s
      end
      t_length = t_data.length
      begin
        p_sock.write_nonblock(t_data)
      rescue Errno::EAGAIN
        return
      end

#       loop do
#         begin
#           written_length = p_sock.write_nonblock(t_data)
#         rescue Errno::EAGAIN
#           break
#         end
#         break if written_length >= t_length
#         t_data = t_data[written_length..-1]
#         break if t_data.empty?
#         t_length = t_data.length
#       end
    end

    # method writes data to socket in a non blocking manner, but doesn't care if there is a error writing data
    def write_once(p_data,p_sock)
      t_data = p_data.dup.to_s
      begin
        p_sock.write_nonblock(t_data)
      rescue Errno::EAGAIN
        return
      end
    end

    # method dumps the object in a protocol format which can be easily picked by a recursive descent parser
    def dump_object(p_data,p_sock)
      object_dump = Marshal.dump(p_data)
      dump_length = object_dump.length.to_s
      length_str = dump_length.rjust(9,'0')
      final_data = length_str + object_dump

#       total_length = final_data.length
#       loop do
#         begin
#           written_length = p_sock.write_nonblock(final_data)
#         rescue Errno::EAGAIN
#           break
#         end
#         break if written_length >= total_length
#         final_data = final_data[written_length..-1]
#         break if final_data.empty?
#         total_length = final_data.length
#       end

      begin
        p_sock.write_nonblock(final_data)
      rescue Errno::EAGAIN
        return
      end
    end

  end
end