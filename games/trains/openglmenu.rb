require 'menu_config'

class OpenGLMenu

  def initialize(o)
    @obj = o
    @level = :main
  end

  def draw
    @level = :main if @level == :quit
    items = MENU[@level]
    
    if not items
      text_out(10, 300, GLUT_BITMAP_HELVETICA_18, "No menu for #{@level}")
      return
    end
    
    GL::BlendFunc(GL::SRC_ALPHA,GL::ONE_MINUS_SRC_ALPHA) # GL::Enable(GL::BLEND) for this to work
    GL::Color(0.2,0.2,0.5,0.5)
    GL::Rect(5,320-(items.size*20+5),300,320)
    GL::LineWidth(3)
    GL::Color(0,0,0.5,0.8)
    GL::Begin(GL::LINE_LOOP)
      GL::Vertex2f(5,320-(items.size*20+5))
      GL::Vertex2f(5, 320)
      GL::Vertex2f(300, 320)
      GL::Vertex2f(300,320-(items.size*20+5))
    GL::End()
    
    GL::Color(0.8,0.8,0.8)
    items.each_with_index { |item, index|
      text_out(10, 300-index*20, GLUT_BITMAP_HELVETICA_18, item[1])
      }
  end
  
  def text_out(x, y, font, string)  
    GL::RasterPos2f(x,y)
    string.each_byte do |c|
      GLUT::BitmapCharacter(font, c)
    end
  end
  
  def key(k)
    items = MENU[@level]
    action = items.select { |i| i[0] == k.chr.upcase}
    return if action == []
    action = action[0][2]
    return (@level = action[:go]) if action[:go]
    @obj.send(action[:cb]) and return (@level = action[:cb]) if action[:cb]
  end 
  
end

