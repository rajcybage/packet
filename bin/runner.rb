PACKET_APP = File.expand_path(File.join(File.dirname(__FILE__) + "/.."))
["bin","config","parser","worker","framework","lib","pimp"].each { |x| $LOAD_PATH.unshift(PACKET_APP + "/#{x}")}

require "packet"

class Foo
  def receive_data p_data
    #t_callback = Packet::Callback.new { |data| show_result(data) }
    # workers[:no_proxy_worker].send_request(:data => p_data)
    ask_worker(:dynamic_worker,:data => p_data, :type => :request)
  end

  def worker_receive p_data
    send_data "#{p_data[:data]}\n"
  end

  def show_result p_data
    send_data("#{p_data[:response]}\n")
  end

#   def connect_back
#     puts "Attempting a reconnection : #{Time.now}"
#     reconnect("localhost",11006,self)
#   end

  def unbind
    puts "remove client close the connection"
  end

  def connection_completed
    puts "Connection completed #{Time.now}"
    #start_worker('dynamic_worker',{ :trigger => "now and then"})
  end

  def post_init
    #  add_periodic_timer(5) { send_data "Hello World: #{Time.now}\n" }
    puts "Calling post_init"
    # send_data "310 <IBM>##ECHO=#{Time.now}##\n"
  end

  def wow
    puts "Wow"
  end
end

Packet::Reactor.run do |t_reactor|
  t_reactor.start_worker("dynamic_worker")
  t_reactor.start_server("localhost", 11006,Foo) do |instance|
    instance.wow
  end
end

