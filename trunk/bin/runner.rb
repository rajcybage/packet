PACKET_APP = File.expand_path(File.join(File.dirname(__FILE__) + "/.."))
["bin","config","parser","worker","framework","lib","pimp"].each { |x| $LOAD_PATH.unshift(PACKET_APP + "/#{x}")}
require "packet"

class Foo
  def receive_data p_data
    #t_callback = Packet::Callback.new { |data| show_result(data) }
    # workers[:no_proxy_worker].send_request(:data => p_data)
    ask_worker(:no_proxy_worker,:data => p_data, :type => :request)
  end

  def worker_receive p_data
    p "***************** : in worker receive of main #{p_data[:data]}"
    send_data "#{p_data[:data]}\n"
  end

  def show_result p_data
    send_data("#{p_data[:response]}\n")
  end

  def connect_back
    puts "Attempting a reconnection : #{Time.now}"
    reconnect("localhost",11006,self)
  end

  def unbind
    add_timer(5) { connect_back }
  end

  def connection_completed
    puts "Connection completed #{Time.now}"
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
  #t_reactor.add_timer(5) { puts "Hello World : #{Time.now}"}
  t_reactor.start_server("localhost", 11006,Foo) do |instance|
    instance.wow
  end
#  t_reactor.connect("localhost",11001,Foo) do |t_instance|
#    t_instance.wow
#  end

end

