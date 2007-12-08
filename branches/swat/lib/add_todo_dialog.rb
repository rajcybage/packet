class AddTodoDialog
  attr_accessor :todo_glade
  def initialize
    @todo_glade = GladeXML.new("#{SWAT_APP}/resources/add_todo.glade") { |handler| method(handler) }
  end
end
