#!/usr/bin/env ruby

require "rubygems"
require 'libglade2'
require "yaml"
SWAT_APP = File.expand_path(File.dirname(__FILE__)+"/..")
["lib"].each { |x| $LOAD_PATH.unshift("#{SWAT_APP}/#{x}"); $LOAD_PATH.unshift("#{SWAT_APP}/#{x}/keybinder")}

require "todo_window"
require "keybinder"

class Swat
  attr_accessor :todo_window
  attr_accessor :status_icon
  attr_accessor :key_binder

  def initialize
    @status_icon = Gtk::StatusIcon.new
    TodoWindow.todo_file_location = "/home/gnufied/notes/todo.org"
    @todo_window = TodoWindow.new("#{SWAT_APP}/resources/todo_window.glade")

    @status_icon.set_icon_name(Gtk::Stock::DIALOG_INFO)
    @status_icon.set_tooltip("Your Task List")
    @status_icon.visible = true
    @status_icon.signal_connect('activate') { show_task_list }
    @status_icon.signal_connect('popup-menu') { |*args| display_context_menu(*args) }

    @key_binder = KeyBinder.new
    bind_proc = lambda { show_task_list }
    @key_binder.bindkey("<Alt>F11",bind_proc)
  end

  def show_task_list
    @todo_window.show_window
  end

  def display_context_menu(*args)
    w,button,activate_time = *args
    menu = Gtk::Menu.new
    menuitem = Gtk::MenuItem.new(" Quit ")
    menuitem.signal_connect("activate") {
      w.set_visible(false)
      Gtk.main_quit
    }
    menu.append(menuitem)

    hidemenuitem = Gtk::MenuItem.new(" Hide ")
    hidemenuitem.signal_connect("activate") {
      @todo_window.hide_window
    }
    menu.append(hidemenuitem)
    menu.show_all
    menu.popup(nil,nil,button,activate_time)
  end

end

Swat.new
Gtk.main
