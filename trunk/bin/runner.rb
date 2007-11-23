EVAL_APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__) + "/.."))
["bin","worker","lib"].each { |x| $LOAD_PATH.unshift(EVAL_APP_ROOT + "/#{x}")}

#WORKER_ROOT = EVAL_APP_ROOT + "/worker"

require "packet"
class Foo
  def receive_data p_data
    send_data(p_data)
    #ask_worker(:no_proxy_worker,:data => p_data, :type => :request)
  end

  def worker_receive p_data
    send_data "#{p_data[:data]}\n"
  end

  def show_result p_data
    send_data("#{p_data[:response]}\n")
  end

  def connection_completed
  end

  def post_init
  end

  def wow
    puts "Wow"
  end
end

Packet::Reactor.run do |t_reactor|
  t_reactor.start_server("localhost", 11006,Foo) do |instance|
    instance.wow
  end
end

