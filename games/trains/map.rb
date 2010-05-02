OPP = {1=>5, 2=>6, 3=>7, 4=>8, 5=>1, 6=>2, 7=>3, 8=>4}

class Case

  attr_accessor :type, :opt

  def initialize(type, opt=nil)
    @type, @opt = type, opt
  end
  
end

class Rails < Case
  
  attr_reader :lines, :selected, :ends
  
  def initialize(lines_arr)
    @type = :rails
    @lines = []
    @ends = Hash.new{|hash, key| hash[key] = Array.new}
    @selected = Hash.new(nil)
    lines_arr.each { |l|
      add_line(l)
      }
    #@selected = 0
  end
  
  def add_line(arr)
    @lines << arr
    @ends[arr[0]] << arr[1]
    @ends[arr[1]] << arr[0]
    @selected[arr[0]] = arr[1] if not @selected[arr[0]]
    @selected[arr[1]] = arr[0] if not @selected[arr[1]]
  end

  def get_end(from)
    @selected[from]
  end
  
  def selected?(line)
    get_end(line[0]) == line[1] and get_end(line[1]) == line[0]
  end
  
  def switch(from)
    ends = @ends[from]
    return if ends.size <= 1
    index = ends.index(@selected[from])
    index += 1
    index = 0 if index >= ends.size
    @selected[from] = ends[index]
  end
  
  #def set_end(from, e)
  #  @selected[from] = e
  #end

private
    
end

class Map

  def initialize
    @map = Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
    begin
      load
    rescue Exception=>e
      @map[0][0]    = Rails.new([[5,1]])
      @map[0][1]    = Rails.new([[5,7]])
      @map[-1][1]   = Rails.new([[3,7]])
      @map[-2][1]   = Rails.new([[3,5]])
      @map[-2][0]   = Rails.new([[1,5]])
      @map[-2][-1]  = Rails.new([[1,3]])
      @map[-1][-1]  = Rails.new([[7,3]])
      @map[0][-1]   = Rails.new([[7,1]])
      save
    end
  end
  
  def load
    File.open('./map.save').each { |line|
      arr = line.scan(/(-{0,1}\d+)\,(-{0,1}\d+)=(.+)$/) 
      lines = arr[0][2].scan(/(\d+),(\d+)/)
      lines = lines.map { |l| [l[0].to_i,l[1].to_i]}
      @map[arr[0][0].strip.to_i][arr[0][1].strip.to_i] = Rails.new(lines)
      }
  end
  
  def save
    f = File.open('./map.save','w')
    each do |x,y,rail|
      s = ""
      rail.lines.each { |l|
        s += ";" if s != ""
        s += l[0].to_s + "," + l[1].to_s
        }
      f << "#{x},#{y}=#{s}\n"
    end
  end
  
  
  def get_case(x,y)
    @map[x][y]
  end
  
  def set_rails(x,y,lines)
    @map[x][y] = Rails.new(lines)
  end
  
  def remove_case(x,y)
    @map[x].delete(y)
  end
  
  def clear
    @map.clear
  end
  
  def get_all_possible_lines(casex, casey)
    lines = []
    lines << [1,5]
    lines << [1,3]
    lines << [1,7]
    lines << [3,7]
    lines << [5,3]
    lines << [5,7]
    lines
  end
  
  def each
    @map.each_pair { |k1,v1|
      v1.each { |k2,v2|
        yield k1,k2,v2 if v2 != {}
        }
      }
  end
  
  def draw
    each { |x,y,c|
      if c == {}
        GL::Color(0.2,0.2,0.2,0.5)
        GL::Rect(x, y, x+1, y+1)
        next
      end
      GL::Color(0.8,0,0,1)
      GL::LineWidth(1)
      c.lines.each { |l|
        GL::Begin(GL::LINES)
          v = get_vector(l[0]) + MVector.new(x,y,0)
          GL::Vertex(v.x, v.y, 0)
          v = get_vector(l[1]) + MVector.new(x,y,0)
          GL::Vertex(v.x, v.y, 0)
        GL::End()
        }
      GL::Color(0,0.8,0,1)
      GL::LineWidth(3)
      c.selected.each { |from,to|
        next if c.ends[from].size < 2
        GL::Begin(GL::LINES)
          vfrom = get_vector(from) + MVector.new(x,y,0)
          GL::Vertex(vfrom.x, vfrom.y, 0)
          v = (get_vector(to)-get_vector(from))*0.4 + vfrom 
          GL::Vertex(v.x, v.y, 0)
        GL::End()
        }
      }
  end
    
  def get_pos(casex, casey, delta, from, to)
    vfrom = get_vector(from)
    vto   = get_vector(to)
    dir = vto - vfrom
    len = dir.length
    
    d = delta * 1/len

    point = MVector.new(casex,casey,0) + vfrom + (dir * d)

    # check if we need to change case
    if delta > len
      casex, casey = get_next(casex, casey, to)
      from = get_opp(to)
      to = get_destination(casex,casey,from)
      delta = delta-len
    elsif delta < 0
      casex, casey = get_next(casex, casey, from)
      to = get_opp(from)
      from = get_destination(casex,casey,to)
        vfrom = get_vector(from)
        vto   = get_vector(to)
        dir = vto - vfrom
        len = dir.length
      delta = len+delta
    end
    
    [point.x, point.y, casex, casey, delta, from, to]
  end
  
  def next_case(casex, casey, from)
    casex, casey = get_next(casex,  casey, get_destination(casex,  casey, from))
    @map[casex][casey] # wil create a {} case if does not exists
  end
  
  def switch_next(casex,  casey, from)
    next_c = next_case(casex,  casey, from)
    return if next_c == {}
    next_from = get_opp(get_destination(casex,  casey, from))
    next_c.switch(next_from)
  end
  
  def get_opp from
    OPP[from]
  end
  
  # send map over the network
  def pack_each
    yield ['m3',1].pack('A2i') # clear
    index = @map.size
    each { |x,y,c|
      rv = ['m4',index,x,y,c.lines.size]
      c.lines.each { |l|
        rv << l[0]
        rv << l[1]
        }
      str = 's' * c.lines.size*2
      yield rv.pack('A2iiis'+str) # rails
      index -= 1
      }
  end
  
  def get_dir_vector(casex, casey, from)
    to = get_destination(casex,casey,from)
    get_vector(to) - get_vector(from)  
  end

private

  #def get_case_coord(point)
  #  [point.x.floor, point.y.floor]      
  #end

  
  def get_next(casex, casey, from)
    case from
      when 1
        [casex, casey+1]
      when 2
        [casex+1, casey+1]
      when 3
        [casex+1, casey]
      when 4
        [casex+1, casey-1]
      when 5
        [casex, casey-1]
      when 6
        [casex-1, casey-1]
      when 7
        [casex-1, casey]
      when 8
        [casex-1, casey+1]
      else
        [casex, casey]
    end
  end
  
  def get_destination(casex,casey,from)
    rails = @map[casex][casey]
    return nil if rails=={} or rails.type != :rails 
    rails.get_end(from)
  end
  
  def get_vector(line_point)
    case line_point
      when 1
        MVector.new(0.5,1,0)      
      when 2
        MVector.new(1,1,0)      
      when 3
        MVector.new(1,0.5,0)      
      when 4
        MVector.new(1,0,0)      
      when 5
        MVector.new(0.5,0,0)      
      when 6
        MVector.new(0,0,0)      
      when 7
        MVector.new(0,0.5,0)
      when 8
        MVector.new(0,1,0)      
      else
        MVector.new(0.5,0.5,0)
    end
  end

end
