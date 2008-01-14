=begin
 There are many ordered hash implementation of ordered hashes, but this one is for packet.
 Nothing more, nothing less.
=end

module Packet
  class TimerStore
    attr_accessor :order
    def initialize
      @order = []
      @container = { }
    end

    def store(timer)
      int_time = timer.scheduled_time.to_i
      @container[int_time] ||= []
      @container[int_time] << timer

      if @container.empty?
        @order << int_time
        return
      end
      if @order.last <= key
        @order << int_time
      else
        index = bin_search_for_key(o,@order.length - 1,int_time)
        @order.insert(index,int_time)
      end
    end

    def bin_search_for_key(lower_index,upper_index,key)
      return upper_index if(upper_index - lower_index <= 1)
      pivot = (lower_index + upper_index)/2
      if @order[pivot] == key
        return pivot
      elsif @order[pivot] < key
        bin_search_for_key(pivot,upper_index,key)
      else
        bin_search_for_key(lower_index,pivot,key)
      end
    end
  end

  def each
    @order.each_with_index do |x,i|
      if x <= Time.now.to_i
        @container[x].each { |timer| yield x }
        @container.delete(x)
        @order.delete_at(i)
      end
    end
  end

  def delete(timer)
    int_time = timer.scheduled_time
    @container[int_time] && @container[int_time].delete(timer)

    if(!@container[int_time] || @container[int_time].empty?)
      @order.delete(timer)
    end
  end
end

