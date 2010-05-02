
  def enable_2D
    vPort = GL.GetIntegerv(GL_VIEWPORT)

    GL.MatrixMode(GL_PROJECTION)
    GL.PushMatrix()
    GL.LoadIdentity()

    GL.Ortho(0, vPort[2], 0, vPort[3], -1, 1)
    GL.MatrixMode(GL_MODELVIEW)
    GL.PushMatrix()
    GL.LoadIdentity()
  end
  
  def disable_2D
    GL.MatrixMode(GL_PROJECTION)
    GL.PopMatrix()   
    GL.MatrixMode(GL_MODELVIEW)
    GL.PopMatrix()	
  end

  def text_out(x, y, font, string)  
    GL::RasterPos2f(x,y)
    string.each_byte do |c|
      GLUT::BitmapCharacter(font, c)
    end
  end

  def draw_analog(pos, value, max)
    draw_numbers(pos, Math::PI, 50)
    draw_hand(pos, value, max, 50)
  end
  
  def draw_numbers(pos, max, r)
    GL::Color(1,1,0.5, 1)
    GL::Begin(GL::LINES)
      16.times do |i|
        angle = i/10.0 * Math::PI
        c = Math.cos(angle)
        s = Math.sin(angle)
        a = c*(r+2)
        b = s*(r+2)      
        x = c*(r+8)
        y = s*(r+8)      
        GL::Vertex2d(a+pos[0],b+pos[1])
        GL::Vertex2d(x+pos[0],y+pos[1])
      end
    GL::End()
  end
  
  def draw_hand(pos, value, max, r)
    GL::Color(1,1,0.5, 1)
    GL::Begin(GL::LINES)
      GL::Vertex2d(pos[0],pos[1])
      angle = Math::PI - value/max * Math::PI
      x = Math.cos(angle)*r
      y = Math.sin(angle)*r      
      GL::Vertex2d(x+pos[0],y+pos[1])
    GL::End()
  end
  
