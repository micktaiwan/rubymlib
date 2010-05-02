#!/usr/bin/ruby

# TODO: réseau
#         envoyer les map edits
#         collisions
# TODO: wagons
# TODO: cam views
# TODO: faire des listes opengl avec le circuit

require 'config'
require 'world'
require 'controls'
require 'joy'
require 'openglmenu'
require 'net'
require 'editor'
require 'train'
require 'enumerator'
require 'opengl_utils'

class TrainWorld < World

  attr_accessor :cam, :controls, :console
  
  def draw
    t = GLUT.Get(GLUT::ELAPSED_TIME)
    # clear
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    GL::LoadIdentity()
    
    # camera
    GL.Rotate(@cam.rot.x, 1.0, 0.0, 0.0)
    GL.Rotate(@cam.rot.y, 0.0, 1.0, 0.0)
    GL.Rotate(@cam.rot.z, 0.0, 0.0, 1.0)
    GL.Translate(-@cam.pos.x, -@cam.pos.y, -@cam.pos.z)

    # ground
    GL.CallList(@ground_list)

    @controls.joy if @joy.present? 
    parse(@net.read)
    
    @editor.map.draw
    draw_peers
    @train.next_step
    @train.draw

    enable_2D
      draw_console
      @train.draw_controls
      @editor.draw  if @editing
      @menu.draw    if CONFIG[:draw][:menu]
    disable_2D
 
    sleep(0.05)    if CONFIG[:sim][:fps_slow]
     
    # END
    GLUT.SwapBuffers()

    @frames += 1
    
    # done after rotate so the cam still follow if told to do so
    @cam.follow if CONFIG[:cam][:follow]
   
    if t - @t0 >= 1000
      send_pos
      seconds = (t - @t0) / 1000.0
      @fps = @frames / seconds
      @train.time_step = 1/(@fps*CONFIG[:sim][:speed_factor])
      @t0, @frames = t, 0
    end
  end
  
  def key(k, x, y)
    if CONFIG[:draw][:menu]
      rv = @menu.key(k)
      CONFIG[:draw][:menu] = nil if rv == :quit
      return
    end
    @controls.action(k.chr,1)
    case k.chr
      when 'e'
        @editing = @editing ? nil : true
      when '1'
        CONFIG[:sim][:fps_slow] = CONFIG[:sim][:fps_slow] ? false : true
      when ' '
        @train.stop
    end
    super
  end
  
  def mouse(button, state, x, y)
    if @editing
      super if not @editor.click(x, y, state)
    else
      super
    end
  end

  def special(k, x, y)
    case k
      when GLUT::KEY_UP
        @train.accelerate(1)
      when GLUT::KEY_DOWN
        @train.accelerate(-1)
      when GLUT::KEY_LEFT
        @train.turn(-1)
      when GLUT::KEY_RIGHT
        @train.turn(1)
      when GLUT::KEY_F1
        CONFIG[:draw][:menu] = CONFIG[:draw][:menu]? nil : true
    end
    super
  end

  def send_pos
    msg = ['mo',(@train.pos.x*100).to_i, (@train.pos.y*100).to_i].pack("A2ii")
    @net.broadcast(msg)
  end

  def broacast_end
    msg = ['en'].pack("A2")
    @net.broadcast(msg)
  end

  def draw_peers
    @net.each_peer { |p|
      next if not p.active
      GL::Color(1, 0, 0, 1)
      GL::PointSize(8)
      GL::Begin(GL::POINTS)
        GL::Vertex(p.pos.x, p.pos.y, 0)
      GL::End()

      GL::Color(0.8, 0.3, 0.3, 1)
      text  = "#{p.name} (#{(Time.now-p.last_packet).to_i})"
      text_out(p.pos.x+0.1, p.pos.y+0.1, GLUT_BITMAP_HELVETICA_12, text)
      }
  end
      
  def init
    GLUT.InitDisplayMode(GLUT::RGBA | GLUT::DEPTH | GLUT::DOUBLE)
    GLUT.InitWindowPosition(0, 0)
    GLUT.InitWindowSize(CONFIG[:draw][:screen_width],CONFIG[:draw][:screen_height])
    GLUT.CreateWindow('train')
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)
    GL.ShadeModel(GL::SMOOTH)
    GL.DepthFunc(GL::LEQUAL)
    GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
    GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::NORMALIZE)
    GL::Enable(GL::POINT_SMOOTH)
    GL::Enable(GL::BLEND) # for the menu, editor

    @ground_list = GL.GenLists(1)
    GL.NewList(@ground_list, GL::COMPILE)
      draw_grid
    GL.EndList()

    @joy      = Joy.new(CONFIG[:joy][:dev])
    @controls = Controls.new(@joy)
    @menu     = OpenGLMenu.new(self)
    @net      = Network.new(CONFIG[:net][:name], CONFIG[:net][:ip] ,CONFIG[:net][:port])
    @editor   = Editor.new(CONFIG[:draw][:screen_width],CONFIG[:draw][:screen_height], @net)
    @editing  = false
    @train    = Train.new(@editor.map)
    @cam.set_follow(@train,:get_pos_vector,:get_dir_vector,{:distance=>3})

    err = GL.GetError
    raise "GL Error code: #{err}" if err != 0
  end
  
  def reshape(width, height)
    @editor.set_size(width, height)
    super
  end

  def ping_all
    @net.ping_all
    MENU[:ping_all] = [['Q', "Q - Back", {:cb=>:display_network}]]
    return true
  end

  def send_map_proposal
    @net.broadcast(['m1'].pack('A2'))
    MENU[:send_map_proposal] = [['Q', "Q - Back", {:cb=>:display_network}]]
    return true
  end
  
  def ask_map
    @net.broadcast(['m2'].pack('A2'))
    MENU[:ask_map] = [['Q', "Q - Back", {:cb=>:display_network}]]
    return true
  end
  
  def save_map
    @editor.map.save
    MENU[:save_map] = [['Q', "Q - Back", {:go=>:main}]]
    return true
  end

  def display_network  
    MENU[:display_network] = []
    @net.each_peer { |p|
      MENU[:display_network] << ['', "#{p.name} #{p.active ? ": #{(Time.now - p.last_packet).to_i}" : "(not active)"}", {}]
      }
    MENU[:display_network] << ['', "", {}]
    MENU[:display_network] << ['S', "S - Send Map", {:cb=>:send_map_proposal}]
    MENU[:display_network] << ['R', "R - Request Map", {:cb=>:ask_map}]
    MENU[:display_network] << ['P', "P - Ping all", {:cb=>:ping_all}]
    MENU[:display_network] << ['Q', "Q - Back", {:go=>:main}]
    return true
  end

  
private  
  
  def parse(m)
    return if not m
    msg   = m[0]
    peer  = m[1]
    case msg[0..1]
      when 'm2' # map request
        @editor.map.pack_each { |p|
          peer.send(p)
          }
      when 'm3' # map request
        @editor.map.clear
      when 'm4' # map request
        command, index, x, y, nblines = msg.unpack('A2iiis')
        str = 's' * nblines*2
        numbers = msg[16..-1].unpack(str)
        lines = []
        numbers.each_slice(2) { |a,b|
          lines << [a,b]
          }
        @editor.map.set_rails(x,y,lines)
    end
  end
  
  def draw_console
    # FPS
    GL::Color(1, 1, 0, 1)
    text_out(10,@screen_height-30, GLUT_BITMAP_HELVETICA_18, @fps.to_i.to_s + " fps")
    # console
    @console.draw
  end

end

t = TrainWorld.new
t.start           # main loop
t.broadcast_end   # we leave, bye !


