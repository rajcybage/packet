require "socket"

sock = TCPSocket.open("localhost",11007)
data = File.open("netbeans.jpg").read
p data.length

100.times do
  sock.write(data)
  select([sock],nil,nil,nil)
  read_data = ""

  loop do
    begin
      while(read_data << sock.read_nonblock(1023)); end
    rescue Errno::EAGAIN
      break
    rescue
      break
    end
  end

  p read_data.length




end
