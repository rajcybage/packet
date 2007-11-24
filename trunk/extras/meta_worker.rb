# FIXME: need to wrap workers within a namespace
module BackgrounDRb
  class MetaWorker < Packet::Worker
    attr_accessor :config_file, :my_schedule, :run_time, :trigger_type, :trigger

    def worker_init
      @config_file = YAML.load(ERB.new(IO.read("#{RAILS_HOME}/config/backgroundrb.yml")).result)
      if @config_file[:schedules]
        @my_schedule = @config_file[:schedules][worker_name.to_sym]
        load_schedule if @my_schedule
      end
      create if respond_to?(:create)
    end

    def receive_data p_data
      case p_data[:type]
      when :request: process_request(p_data)
      when :response: process_response(p_data)
      end
    end

    def load_schedule
      case @my_schedule[:trigger_args]
      when String
        @trigger_type = :cron_trigger
        cron_args = @my_schedule[:trigger_args] || "0 0 0 0 0"
        @trigger = BackgrounDRb::CronTrigger.new(cron_args)
      when Hash
        @trigger_type = :trigger
        @trigger = BackgrounDRb::Trigger.new(@my_schedule[:trigger_args])
      end
      @run_time = @trigger.fire_time_after(Time.now).to_i
    end

    def register_status p_data
      status = {:type => :status,:data => p_data}
      send_data(status)
    end

    def send_response input,output
      input[:data] = output
      input[:type] = :response
      send_data(input)
    end

    def unbind; end

    def connection_completed; end

    # we are overriding the function that checks for timers
    def check_for_timer_events
      super
      return unless @my_schedule
      if @run_time < Time.now.to_i
        self.send(@my_schedule[:worker_method]) if self.respond_to?(@my_schedule[:worker_method])
        @run_time = @trigger.fire_time_after(Time.now).to_i
      end
    end
  end
end

