class Console

  def initialize#(sw, sh)
    @queue = Array.new
    @num = 0
  end
  
  def push txt
    @num += 1
    @queue.insert 0, "#{@num}: #{txt}"
    @queue.pop if @queue.size > 7
  end
  
  def draw
    #clean
    (0..@queue.size-1).each { |y|
      if y == 0
        GL::Color(0.8,0.8,0.8)
      else
        GL::Color(0.3,0.3,0.3)
      end
      text_out(10,100-y*12, GLUT_BITMAP_HELVETICA_12, @queue[y])
      }
  end
  
  def text_out(x, y, font, string)  
    GL::RasterPos2f(x,y)
    string.each_byte do |c|
      GLUT::BitmapCharacter(font, c)
    end
  end


end

