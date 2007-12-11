=begin
 class implements all todo data
=end

class TodoData
  attr_accessor :config_file,:todo_container
  def initialize(config_file)
    @config_file = config_file
    todo_lines = []
    @todo_container = {}
    current_category = nil
    File.open(@config_file) {|fl| todo_lines = fl.readlines() }
    todo_lines.each do |todo_line|
      todo_line.strip!.chomp!
      next if todo_line.nil? or todo_line.empty?
      case todo_line
      when /^\*{1}\ (.+)?/
        current_category = $1
        @todo_container[current_category] ||= []
      when /^(\*{2,})\ TODO\ (.+)?/
        priority = $1.size
        item = OpenStruct.new(:priority => priority, :flag => true, :text => $2)
        @todo_container[current_category] << item
      when /^(\*{2,})\ DONE\ (.+)?/
        priority = $1.size
        item = OpenStruct.new(:priority => priority, :flag => false, :text => $2)
        @todo_container[current_category] << item
      end
    end
  end

  def open_tasks
    @todo_container.each do |category,todo_array|
      next if todo_array.empty?
      todo_array.sort! { |x,y| x.priority <=> y.priority }
      todo_array.reject! { |x| !x.flag }
      yield(category,todo_array)
    end
  end

  def open_tasks_with_index
    @todo_container.each_with_index do |category,todo_array,index|
      todo_array.sort! { |x,y| x.priority <=> y.priority }
      todo_array.reject! { |x| !x.flag }
      yield(category,todo_array,index)
    end
  end

  def dump
    File.open(@config_file,'w') do |fl|
      @todo_container.each do |category,todo_array|
        fl << "* #{category}\n"
        todo_array.each do |todo_item|
          fl << "#{priority_star(todo_item.priority)} #{todo_item.flag ? 'TODO' : 'DONE'} #{todo_item.text}\n"
        end
      end
    end
  end

  def priority_star(count)
    foo = ''
    count.times { foo << '*'}
    return foo
  end

  def delete(category,task)
    @todo_container[category].each do |task_item|
      if task_item.text == task
        task_item.flag = false
      end
    end
  end

  def categories
    return @todo_container.keys
  end

  def insert(category,task,priority)
    @todo_container[category] ||= []
    @todo_container[category] << OpenStruct.new(:priority => priority, :text => task.gsub(/\n/,' '), :flag => true)
  end

end
