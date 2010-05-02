#!/usr/bin/env ruby

require 'gui'
require 'conf'

require 'prot/tcp_chat'
require 'prot/irc' # temp: need to load protocols dynamically

class Client < GuiGlade


  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    super(path_or_data, root, domain , localedir , flag)
    #@c = ChatClient.new(HOST,PORT)
    @c = IRC.new # temp: need to have a pool of connections to different protocol servers
    Gtk.timeout_add(50) { receive_data }
  end
  
  
  def receive_data
    txt = @c.gets
    @glade['chat'].insert_at_cursor(txt) if txt != nil
    true # needed for GTK
  end
  

  def on_main_destroy(widget)
    puts "Exiting..."
    @c.disconnect
    Gtk.main_quit
  end
  
  def on_btn_connect_clicked(widget)
    puts "Connecting to #{HOST}:#{PORT}..."
    @c.connect
  end
  
  def on_btn_send_clicked(widget)
    #puts "Sending #{@glade['msg'].text}..."
    begin
      @c.send @glade['msg'].text
      @glade['msg'].text = ''
    rescue
      puts "error: #{$!}"
    end
  end
  
  def on_toolbutton2_clicked(widget)
    puts "Disconnecting..."
    @c.disconnect
  end
  def on_msg_key_press_event(widget, arg0)
    if(Gdk::Keyval.to_name(arg0.keyval) == "Return")
      on_btn_send_clicked(nil)
    end
  end
  def on_btn_clear_clicked(widget)
    @glade['chat'].buffer.text = ''
  end
end

PROG_PATH = "gui.glade"
PROG_NAME = "Chat"

Client.new(PROG_PATH, nil, PROG_NAME)
Gtk.main

