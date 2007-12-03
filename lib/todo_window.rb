class TodoWindow
  attr_accessor :todo_data,:glade,:todo_window

  TreeItem = Struct.new('TreeItem',:description, :priotiry,:category)
  @@todo_file_location = nil

  def self.todo_file_location= (filename)
    @@todo_file_location = filename
  end

  def on_todo_window_delete_event
    hide_window
    return true
  end

  def on_todo_window_destroy_event
    return true
  end

  def on_todo_window_key_press_event(widget,key)
    if key.keyval == 65307
      hide_window
    end
  end

  def on_reload_button_clicked
    # FIXME: perhaps this synchronization with SVN should be made optional.
    # since automatically checkin in files could be a source of irritation
    # system("svn up #{@@todo_file_location}")
    read_org_file
    @model = create_model
    load_available_lists
    @todo_view.expand_all
  end

  def initialize path
    @glade = GladeXML.new(path) { |handler| method(handler) }
    @todo_view = @glade.get_widget("todo_view")
    @todo_window = @glade.get_widget("todo_window")

    @todo_selection = @todo_view.selection
    @todo_selection.mode = Gtk::SELECTION_SINGLE

    read_org_file
    @model = create_model
    load_available_lists
    add_columns
    @todo_view.expand_all
    @todo_window.hide
  end

  def show_window
    @todo_window = @glade.get_widget("todo_window")
    @todo_window.show
  end

  def hide_window
    @todo_window.hide
  end

  def load_available_lists
    @todo_view.model = @model
    @todo_view.rules_hint = true
    @todo_view.selection.mode = Gtk::SELECTION_MULTIPLE
  end

  def on_checkin_button_clicked
    puts "checking in code now"
    system("svn ci #{@@todo_file_location} -m 'foo'")
  end

  def add_columns
    model = @todo_view.model
    renderer = Gtk::CellRendererText.new
    renderer.xalign = 0.0

    col_offset = @todo_view.insert_column(-1, 'Category', renderer, 'text' => 0,'background' => 1,:weight => 2)
    column = @todo_view.get_column(col_offset - 1)
    column.clickable = true
    @todo_view.expander_column = column
  end

  def create_model
    model = Gtk::TreeStore.new(String,String,Fixnum)

    todo_data.each do |key,value|
      iter = model.append(nil)
      iter[0] = key
      iter[1] = "white"
      iter[2] = 900
      value.each do |todo_item|
        child_iter = model.append(iter)
        child_iter[0] = todo_item.description
        child_iter[1] = chose_color(todo_item)
        child_iter[2] = 500
      end
    end
    return model
  end

  def chose_color(todo_item)
    case todo_item.priotiry
      when 1: 'yellow'
      when 0: 'blue'
      when 2: '#E3B8B8'
      when 3: '#15B4F1'
      when 4: '#F1F509'
    end
  end

  # could be written in a better way
  def read_org_file
    @todo_data = {}
    File.open(@@todo_file_location) do |fl|
      all_lines = fl.readlines
      current_category = nil
      all_lines.each do |todo_line|
        todo_line.strip!.chomp!
        next if todo_line.nil? or todo_line.empty?

        if(todo_line !~ /(TODO|DONE)/i or todo_line =~ /^\*{1}\ /)
          category_name = todo_line.split('*')[1].strip
          @todo_data[category_name] ||= []
          current_category = category_name
        elsif todo_line =~ /TODO/i
          todo_view_str = todo_line.gsub(/TODO/i,'')
          todo_view_str.gsub!(/\*/,'').strip!
          todo_item = TreeItem.new(todo_view_str,get_priority(todo_line),current_category)
          @todo_data[current_category] << todo_item
        end
      end # end of line iterator
    end # end of file open thingy
  end # end of read_org_file method

  def get_priority(main_str)
    stars = $1 if main_str =~ /^(\*+)/
    return stars.size
  end
end

