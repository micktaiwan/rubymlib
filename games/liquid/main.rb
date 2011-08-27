#!/usr/bin/ruby

require 'config'
require 'world'
require 'particule'
require 'opengl_utils'

class LiquidWorld < World
  
  def draw
    # clear
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    GL::LoadIdentity()
    GL.Translate(0, 0, -10)
    draw_grid
    #draw_arrows
    draw_particules
    #sleep(0.05)    if CONFIG[:sim][:fps_slow]
    GLUT.SwapBuffers()
    @frames += 1
  end
  
  def mouse(button, state, x, y)
    #super
    x,y = calc_mouse_pos(x,y)
    puts x, y
    point = MVector.new(x,y,0)
    @particules.each { |p|
      if p.pos.dist(point) < 0.5
        p.speed += MVector.new(0.001,0.001,0)
      end
      }

  end

  def calc_mouse_pos(x,y)
    x -= CONFIG[:draw][:screen_width] / 2
    y -= CONFIG[:draw][:screen_height] / 2
    [x/73.0,y/73.0]
  end

  def special(k, x, y)
    super
  end

  def draw_particules
    GL::Color(1, 0, 0, 1)
    GL::PointSize(CONFIG[:draw][:point_size])
    @particules.each { |p|
      # change particules speed in function other other particules speed
      p.acc = neib_speed(p)
      p.update
      GL::Begin(GL::POINTS)
        GL::Vertex(p.pos.x, p.pos.y, 0)
      GL::End()
      }
  end
  
  def neib_speed(c)
    acc = MVector.new
    @particules.each { |p|
      next if p == c
      acc += p.speed/10 if p.pos.dist(c.pos) < 0.5
      }
    acc
  end
      
  def init
    GLUT.InitDisplayMode(GLUT::RGBA | GLUT::DEPTH | GLUT::DOUBLE)
    GLUT.InitWindowPosition(0, 0)
    GLUT.InitWindowSize(CONFIG[:draw][:screen_width],CONFIG[:draw][:screen_height])
    GLUT.CreateWindow('liquid')
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)
    GL.ShadeModel(GL::SMOOTH)
    GL.DepthFunc(GL::LEQUAL)
    GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
    #GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::NORMALIZE)
    #GL::Enable(GL::POINT_SMOOTH)
    #GL::Enable(GL::BLEND) # for the menu, editor
    #enable_2D

    @particules    = []
    (1..50).each {
      @particules << Particule.new(rand(1000)/900.0-0.5,rand(1000)/900.0-0.5)
      }
  end
  
  def reshape(width, height)
    super
  end

  
private  
  
end

t = LiquidWorld.new
t.start           # main loop


