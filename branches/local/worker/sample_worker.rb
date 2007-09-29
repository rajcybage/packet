class SampleWorker < Packet::CPUWorker
  set_worker_name :sample_worker

  def receive_data p_data
    p "#{p_data}"
  end

  def receive_internal_data p_data
    t_data = p_data
    t_result = send(t_data[:function],t_data)
    send_data(:response => t_result,:callback_signature => t_data[:callback_signature])
  end

  def add(t_data)
    eval(t_data[:data])
  end
end

