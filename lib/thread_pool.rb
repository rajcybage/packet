module Packet
  class WorkData
    attr_accessor :data,:block
    def initialize(*args,&block)
      @data = args
      @block = block
    end
  end

  class ThreadPool
    attr_accessor :size
    attr_accessor :threads
    attr_accessor :work_queue
    def initialize(size)
      @size = size
      @threads = []
      @work_queue = Queue.new
      @running_tasks = Queue.new
      @size.times { add_thread }
    end
    def defer(*args,&block)
      @work_queue << WorkData.new(args,&block)
    end

    def add_thread
      @threads << Thread.new do
        while true
          task = @work_queue.pop
          @running_tasks << task
          if task.data && !task.data.empty?
            task.block.call(*(task.data))
          else
            task.block.call
          end
          @running_tasks.pop
        end
      end
    end

    # method ensures exclusive run of deferred tasks for 2 seconds, so as they do get a chance to run.
    def exclusive_run
      if @running_tasks.empty? && @work_queue.empty?
        return
      else
        sleep(0.5)
        return
      end
    end

  end # end of ThreadPool class

end # end of Packet module
