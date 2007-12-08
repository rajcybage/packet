=begin
  This file contains meta data information about todos being clicked and stuff
=end

class SwatMetaData
  attr_accessor :meta_data
  attr_accessor :meta_data_file_location,:todo_file

  def initialize(config_file,currently_open_todos)
    @meta_data_file_location = config_file
    @todo_file = todo_file
    if File.exists?(@meta_data_file_location)
      @meta_data = YAML.load(ERB.new(IO.read(config_file)).result)
    else
      @meta_data = {}
    end
  end

  # update meta_data with new todos
  def update_meta_data(meta_data = nil)

  end

  # method dumps data to file
  def dump_data
    File.open(@meta_data_file_location,'w') { |f| f.write(YAML.dump(@meta_data))}
  end

  # reads current todo file and generates meta data
  def generate_meta_data

  end
end
