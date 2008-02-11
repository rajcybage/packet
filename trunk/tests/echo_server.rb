require File.join(File.dirname(__FILE__) + "/runner")

class Foo
  def receive_data data
    send_data data
  end
  
  def post_init
    puts "An external client connected" 
  end
  
  def unbind
    puts "external client disconnected" 
  end
end

class Bar
  
  def receive_data data
    puts "received #{data}" 
    @count += 1
  end
  
  def post_init
    @count = 0
    puts "calling post init in client handler" 
  end
  
  def connection_completed
    100.times { |x| send_data("lol : #{x}\n")}
  end
  
  def unbind
    puts "server dropped connection" 
  end
end

Packet::Reactor.run do |t_reactor|
  t_reactor.start_server("0.0.0.0",11007,Foo)
  t_reactor.connect("0.0.0.0",11007,Bar)
end



