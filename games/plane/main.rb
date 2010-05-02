#!/usr/bin/ruby
#require 'profile'
require 'config'
require 'world'
require 'particle_system'
require 'dsl'

class PlaneWorld < World
  
  def draw
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

    # ps
    if(@editing)
      #reload file
      d = File.stat('objects.rb').mtime
      if d != @old_file_stat
        @dsl.reload
        @old_file_stat = d
      end
    else
      @ps.next_step
    end

    # draw particles and forces
    GL::PointSize(8)
    GL::LineWidth(3)
    @ps.particles.each { |p|
      GL::Color(0.6, 0.6, 0.6)
      GL::Begin(GL::POINTS)
        v(p.current.x,p.current.y,p.current.z)
      GL::End()
      p.forces.each { |f|
        next if f.type == :gravity
        case f.type
        when :motor
          GL::Color(0.2, 0.8, 0.2)
        when :uni
          GL::Color(0.2, 0.2, 0.8)
        else
          GL::Color(0.8, 0.4, 0.2)
        end
        v = p.current+(f.vector/(9.81*2))
        GL::Begin(GL::LINES)
          v(p.current.x,p.current.y,p.current.z)
          v(v.x,v.y,v.z)
        GL::End()
        }
      }
    GL::PointSize(1)
    GL::LineWidth(1)

    # draw constraints
    GL::Color(1,0,0)
    @ps.constraints.each { |c|
      next if c.type != :string
      GL::Begin(GL::LINES)
        p = c.particles[0]
        v(p.current.x,p.current.y,p.current.z)
        p = c.particles[1]
        v(p.current.x,p.current.y,p.current.z)
      GL::End()
      }
    
    # board
    #draw_board
    
    draw_console

    # END
    GLUT.SwapBuffers()

    @frames += 1
    t = GLUT.Get(GLUT::ELAPSED_TIME)
    
    x = @cam.pos.x = Math.cos(t/50000.0)*6
    y = @cam.pos.y = Math.sin(t/50000.0)*6
    scale = 45/Math.atan(1) 
    a = (scale*Math.atan2(y,x))+90
    @cam.rot.z = -a
   
    if t - @t0 >= 1000
      seconds = (t - @t0) / 1000.0
      @fps = @frames / seconds
      @ps.time_step = 1/@fps
      @t0, @frames = t, 0
      exit if defined? @autoexit and t >= 999.0 * @autoexit
    end
  end
  
  def key(k, x, y)
    case k
      when ?q
        @plane.add_thrust
      when ?w
        @plane.remove_thrust
      when ?x
        @plane.pitch += 5
      when ?s
        @plane.pitch -= 5
      when ?a
        @plane.heading += 5
      when ?z
        @plane.heading -= 5
      when ?e
        @plane.roll -= 5
      when ?r
        @plane.roll += 5
      when 13 # Enter
        @editing = @editing==true ? nil : true
      when 8 # Backspace
        @dsl.reload
    end
    super
  end
  
  def init
    GLUT.InitDisplayMode(GLUT::RGBA | GLUT::DEPTH | GLUT::DOUBLE)
    GLUT.InitWindowPosition(0, 0)
    GLUT.InitWindowSize(1280, 940)
    GLUT.CreateWindow('World')
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)
    GL.ShadeModel(GL::SMOOTH)
    GL.DepthFunc(GL::LEQUAL)
    GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
    GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::NORMALIZE)
    GL::Enable(GL::POINT_SMOOTH);

    @ground_list = GL.GenLists(1)
    GL.NewList(@ground_list, GL::COMPILE)
      draw_grid
    GL.EndList()

    @ps = ParticleSystem.new
    @dsl = DSL.new(@ps, @console)
    @dsl.reload 
    @editing= nil
    @old_file_stat = nil

    err = GL.GetError
    raise "GL Error code: #{err}" if err != 0
  end

  
private  


  def draw_board
    enable_2D
    GL::Color(0, 1, 0)
    #draw_control(0, @plane.inputs[:thrust], 10)
    #draw_control(1, @plane.lift.length, 0.01)
    #draw_control(2, @plane.drag.length, 0.01)
    #draw_control(3, @plane.gravity.length, 0.01)
    disable_2D
  end
  
  def draw_console
    enable_2D
    # FPS
    GL::Color(1, 1, 0)
    @console.text_out(10,@screen_height-30, GLUT_BITMAP_HELVETICA_18, @fps.to_i.to_s + " fps")
    @console.draw
    disable_2D
  end

  def draw_control(place, value, max)
    GL.Begin(GL::LINE_LOOP)
      GL.Vertex2f(10+place*25, 2)
      GL.Vertex2f(30+place*25, 2)
      GL.Vertex2f(30+place*25, 82)
      GL.Vertex2f(10+place*25, 82)
    GL.End()
    GL.Begin(GL::QUADS)
      GL.Vertex2f(10+place*25, 2+(value/max.to_f)*80)
      GL.Vertex2f(30+place*25, 2+(value/max.to_f)*80)
      GL.Vertex2f(30+place*25, 2)
      GL.Vertex2f(10+place*25, 2)
    GL.End()
  end

end

PlaneWorld.new.start
