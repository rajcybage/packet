require File.expand_path(File.dirname(__FILE__)+"/runner")

class Foo
  def receive_data p_data
    t_callback = Packet::Callback.new { |data| show_result(data) }
    send_to_worker(workers[:sample_worker],
                   :data => p_data,:function => :add, :callback => t_callback)
  end

  def receive_from_sample_worker p_data

  end

  def show_result p_data
    send_data("#{p_data[:response]}\n")
  end

  def unbind
    p "Client disconnected"
  end

  def connection_completed
    p "Connection for client completed"
  end
end

Packet::Reactor.run do
  Packet::Reactor.start_server("localhost",11006,Foo) do
    p "Hello world"
  end
end
