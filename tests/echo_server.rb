require File.join(File.dirname(__FILE__) + "/runner")
require "thread" 

class Foo
  def receieve_data data
    send_data data
  end
  
  def post_init
    puts "An external client connected" 
  end
  
  def unbind
    puts "external client disconnected" 
  end
end

Packet::Reactor.run do |t_reactor|
  t_reactor.start_server("0.0.0.0",11007,Foo)
end
