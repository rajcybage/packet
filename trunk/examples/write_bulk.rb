require "socket"

sock = TCPSocket.open("localhost",11007)
data = File.open("netbeans.jpg").read
p data.length

1.times do
#   sock.write(data)
#   select([sock],nil,nil,nil)
#   read_data = ""

#   loop do
#     begin
#       while(read_data << sock.read_nonblock(1023)); end
#     rescue Errno::EAGAIN
#       break
#     rescue
#       break
#     end
#   end

#   p read_data.length
  written_length = sock.write(data)
  p "Write Length: #{written_length}"
  read_length = sock.read(written_length)
  p "Read length: #{read_length.length}"
end

