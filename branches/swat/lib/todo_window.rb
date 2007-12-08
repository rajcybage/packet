require "enumerator"

class TodoWindow
  attr_accessor :todo_data,:glade,:todo_window

  TreeItem = Struct.new('TreeItem',:description, :priority,:category)
  @@todo_file_location = nil
  @@meta_data_file = nil

  def self.meta_data_file= (file); @@meta_data_file = file; end
  def self.todo_file_location= (filename); @@todo_file_location = filename; end

  def on_todo_window_delete_event
    hide_window
    return true
  end

  def on_todo_window_destroy_event; return true; end

  # add a new todo here
  # create a new dialog button for adding a todo, add that to the org file
  # update the disply.
  def on_add_todo_button_clicked
    puts "Someone clicked add button"
  end

  def on_todo_window_key_press_event(widget,key)
    hide_window if Gdk::Keyval.to_name(key.keyval) =~ /Escape/i
  end

  def on_reload_button_clicked
    read_org_file
    @model = create_model
    load_available_lists
    @todo_view.expand_all
  end

  def initialize path
    @glade = GladeXML.new(path) { |handler| method(handler) }
    @todo_view = @glade.get_widget("todo_view")
    @todo_window = @glade.get_widget("todo_window")
    window_icon = Gdk::Pixbuf.new("#{SWAT_APP}/resources/todo.png")
    @todo_window.icon_list = [window_icon]
    @todo_window.title = "Your TaskList"
    @todo_selection = @todo_view.selection
    @todo_selection.mode = Gtk::SELECTION_SINGLE

    read_org_file
    @model = create_model
    load_available_lists
    add_columns
    connect_custom_signals
    @todo_view.expand_all
    @todo_window.hide
  end

  def connect_custom_signals
    # create an instance of context menu class and let it rot
    @todo_context_menu = TodoContextMenu.new(" Mark as Done ")

    @todo_view.signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton and event.button == 3
        @todo_context_menu.todo_menu.popup(nil, nil, event.button, event.time)
      end
    end
    @todo_view.signal_connect("popup_menu") { @todo_context_menu.todo_menu.popup(nil, nil, 0, Gdk::Event::CURRENT_TIME) }

    # FIXME: implement fold and unfold of blocks
    @todo_view.signal_connect("key-press-event") do |widget,event|
      if event.kind_of? Gdk::EventKey
        key_str = Gdk::Keyval.to_name(event.keyval)
        if key_str =~ /Left/i
          #fold the block
        elsif key_str =~ /Right/i
          #unfold the block
        end
      end
    end
  end

  def display_context_menu(widget,button)
    selection = widget.selection
    if iter = selection.selected
    end
  end

  def show_window
    @todo_window = @glade.get_widget("todo_window")
    @todo_window.show
  end

  def hide_window; @todo_window.hide; end

  def load_available_lists
    @todo_view.model = @model
    @todo_view.rules_hint = false
    @todo_view.selection.mode = Gtk::SELECTION_SINGLE
  end

  def on_sync_button_clicked
    system("svn up #{@@todo_file_location}")
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
    case todo_item.priority
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
          todo_view_str = todo_line.gsub(/TODO/,'')
          todo_view_str.gsub!(/\*/,'').strip!
          todo_view_str = wrap_line(todo_view_str)
          todo_item = TreeItem.new(todo_view_str,get_priority(todo_line),current_category)
          @todo_data[current_category] << todo_item
        end
      end # end of line iterator
    end # end of file open thingy
    sort_by_priority
  end # end of read_org_file method

  def get_priority(main_str)
    stars = $1 if main_str =~ /^(\*+)/
    return stars.size
  end

  def sort_by_priority
    @todo_data.each do |key,value|
      value.sort! { |x,y| x.priority <=> y.priority }
    end
    @todo_data.delete_if { |key,value| value.empty? }
  end

  def wrap_line(line)
    line_width,sep = 10,' '
    words = line.split(sep)
    return words.join(sep) if words.length < line_width
    new_str = []
    words.each_slice(line_width) { |x| new_str << x.join(sep) }
    return new_str.join("\n")
  end

end

