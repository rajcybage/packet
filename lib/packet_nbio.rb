module Packet
  module NbioHelper
    def packet_classify(original_string)
      word_parts = original_string.split('_')
      return word_parts.map { |x| x.capitalize}.join
    end

    def gen_worker_key(worker_name,job_key = nil)
      return worker_name if job_key.nil?
      return "#{worker_name}_#{job_key}".to_sym
    end

    def read_data(t_sock)
      sock_data = ""
      begin
        while(t_data = t_sock.recv_nonblock(1023))
          raise DisconnectError.new(t_sock) if t_data.empty?
          sock_data << t_data
        end
      rescue Errno::EAGAIN
        return sock_data
      rescue Errno::EWOULDBLOCK
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
        loop do
          puts "looping boy" 
          break if t_length <= 0
          written_length = p_sock.write_nonblock(t_data)
          puts "written length : #{written_length}" 
          #p_sock.flush
          t_data = t_data[written_length..-1]
          t_length = t_data.length
        end
      rescue Errno::EAGAIN
        puts "error eagain"
        return
      rescue Errno::EPIPE
        puts "pipe error"
        raise DisconnectError.new(p_sock)
      rescue Errno::ECONNRESET
        puts "peer connrest"
        raise DisconnectError.new(p_sock)
      rescue
        puts $!.to_s
        raise DisconnectError.new(p_sock)
      end
    end

    # method writes data to socket in a non blocking manner, but doesn't care if there is a error writing data
    def write_once(p_data,p_sock)
      t_data = p_data.dup.to_s
      written_length = 0
      data_length = t_data.length
      begin
        written_length = p_sock.write_nonblock(t_data)
        if written_length == data_length
          return "" 
        else
          return t_data[written_length..-1]
        end
      rescue Errno::EAGAIN
        return t_data[written_length..-1]
      rescue Errno::EPIPE
        raise DisconnectError.new(p_sock)
      end
    end

    # method dumps the object in a protocol format which can be easily picked by a recursive descent parser
    def dump_object(p_data,p_sock)
      object_dump = Marshal.dump(p_data)
      dump_length = object_dump.length.to_s
      length_str = dump_length.rjust(9,'0')
      final_data = length_str + object_dump
      begin
        p_sock.write_nonblock(final_data)
      rescue Errno::EAGAIN
        puts "EAGAIN Error while writing socket"
        return
      rescue Errno::EINTR
        puts "Interrupt error"
        return
      rescue Errno::EPIPE
        puts "Pipe error"
        raise DisconnectError.new(p_sock)
      end
    end
  end
end
