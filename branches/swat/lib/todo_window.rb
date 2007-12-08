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
    @add_todo = AddTodoDialog.new
  end

  def on_todo_window_key_press_event(widget,key)
    hide_window if Gdk::Keyval.to_name(key.keyval) =~ /Escape/i
  end

  def on_reload_button_clicked
    @todo_data = TodoData.new(@@todo_file_location)
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

    @todo_data = TodoData.new(@@todo_file_location)
    @model = create_model
    load_available_lists
    add_columns
    connect_custom_signals
    @todo_view.expand_all
    @todo_window.hide
  end

  def connect_custom_signals
    # create an instance of context menu class and let it rot
    @todo_context_menu = TodoContextMenu.new(" Mark as Done ") { mark_task_as_done }

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

  def mark_task_as_done
    selection = @todo_view.selection
    if iter = selection.selected
      selected_category = iter.parent[0]
      task = iter[0]
      p selected_category,task
      @todo_data.delete(selected_category,task)
      @todo_view.model.remove(iter)
      @todo_data.dump
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

  # checks out the new todo file
  # checks in the new todo file
  # writes in memory meta data statistics to yaml file
  # refreshes the view
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

    todo_data.open_tasks do |key,value|
      iter = model.append(nil)
      iter[0] = key
      iter[1] = "white"
      iter[2] = 900
      value.each do |todo_item|
        child_iter = model.append(iter)
        child_iter[0] = todo_item.text
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


end

