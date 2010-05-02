require "Line"
require "../MLib/MTree"
#require "Utils"
require 'ftools'

class MFile

   attr_reader :nb_actions

   def format_action(n,tab)
      str = '*'
      puts tab
      0.upto(tab) { |i| str += "\t" }
      str += "#{n.value.text.chomp}\n" 
      str
   end
   
   def write_node(n,tab)
      str = ''
      if n.value.mods.member?('*')
         str += format_action(n,tab)
      end
      n.children.each { |child_node| 
         str += write_node(child_node, tab+1)
         }
      str
   end
   
   def export_actions
      file = File.new(@path+".actions.txt", "w")
      n = nil
      lastindent = -1;
      while(true)
         n = @tree.getnextnode(n)
         break if n == nil
         str = write_node(n,0)
         file.write str if str != ''
      end
      file.close
   end
  
  def export_to_freemind
    file = File.new(@path+".mm", "w")
    file.write "<map version=\"0.8.0\">\n<node TEXT=\"#@path\">\n"
    n = nil
    lastindent = -1;
    while(true)
      n = @tree.getnextnode(n)
      break if n == nil
      styles = ""
      #next if n.children.size > 1
      (n.value.indent..lastindent).each {file.write("</node>\n")} if n.value.indent <= lastindent
      lastindent = n.value.indent
      styles += " style=\"bubble\"" if n.value.mods.member?('*')
      styles += " color=\"#ff0000\"" if n.value.mods.member?('!')
      styles += " color=\"#555555\"" if n.value.mods.member?('#')
      styles += " color=\"#00ff00\"" if n.value.mods.member?(' ')
      file.write "<node#{styles} POSITION=\"right\" TEXT=\"#{n.value.text.chomp}\">\n" ##{n.value.indent}:#{n.children.size}:
      file.write "<icon BUILTIN=\"flag\"/>\n" if n.value.mods.member?('!')
      file.write "<icon BUILTIN=\"button_ok\"/>\n" if n.value.mods.member?(' ')
      file.write "<icon BUILTIN=\"messagebox_warning\"/>\n" if n.value.mods.member?('*')
      file.write "<font BOLD=\"true\" NAME=\"SansSerif\" SIZE=\"12\"/>\n" if n.value.mods.member?('*')
    end
    (0..lastindent).each {file.write "</node>\n"}
    file.write "</node>\n</map>\n"
    file.close
  end

  private

  def initialize(p)
    @path = p
    @tree = MTree.new
    @nb_actions = 0
    parse
    @n = nil
  end

  def parse

    file            = File.new(@path, "r")
    i               = 0
    lastindent      = 0
    nodes           = []
    indentmodifier  = 0
    bigtitle        = 0
    ignorebigtitle  = false
    
    file.each_line do |line|
      i += 1
      next if line.strip.empty?
      indent,mods,owner,text = parseLine(line)
      # count nb actions
      @nb_actions += 1 if(mods.member?('*'))
      # continuation
      if mods.member?('\\') and nodes.size > 0
        nodes[-1].value.text += '&#xa;'+text.chomp
        next
      end
      # titles
      if mods.member?('T')
        if nodes.size > 0 && text.size == nodes[-1].value.text.size # little title
          nodes[-1].value.indent = bigtitle
          lastindent = bigtitle
          #puts "bt: #{nodes[-1].value.text} (#{nodes[-1].value.indent})"
          indentmodifier = bigtitle+1
        elsif nodes.size > 0 && text.size < nodes[-1].value.text.size
          #puts nodes[-1].value.text
          lastindent += 1
          #puts "li"
          l = Line.new(i,lastindent,['!'],"","title error")
          i += 1
          nodes << @tree.addChild(l,nodes[-1])
          indentmodifier = bigtitle+1
        else  # big title
          ignorebigtitle = !ignorebigtitle
          if ignorebigtitle
            bigtitle = 0
          else
            bigtitle = 1
          end
          indentmodifier = bigtitle
        end
        next
      end
      indent += indentmodifier
      #puts "#{text} i:#{indent},li:#{lastindent}"
      # if a step is missing
      while(indent - lastindent > 1)
        #puts "ms: #{text}"
        lastindent += 1
        l = Line.new(i,lastindent,['!'],"","[misstep]")
        i += 1
        nodes <<  @tree.addChild(l,nodes[-1])
      end
      # create the line
      l = Line.new(i,indent,mods,owner,text)

      # for building the tree we keep track of last nodes added, but we must delete the
      # last nodes when we go back one or more level
      (indent..lastindent).each {nodes.delete(-1)}
      # adding to the tree
      nodes << @tree.addChild(l,nodes[-1])
      lastindent = indent
      #puts "indent = #{indent}, mods = #{mods}, owner = #{owner}" if indent > 0 and mods != []
    end
    file.close
    #puts "======== File: #@path" if @tree.size > 0
  end

  def parseLine(line)
    i = 0
    t = 0
    mods = []
    owner = ""
    # modifiers
    if(line[0].chr=='\\')
      mods << '\\'
      i += 1
    end
    if(line[0..2]=='===') # gros titre
      mods << 'T'
    end
    while (line[i..(i+2)] =~ /^\(.\)/)
      mods << line[i+1].chr
      i += 3
      #puts line 
      #puts "modifiers = #{modifiers}"
    end
    if(mods.member?('*'))
      #error if space betwen modifiers and owner of action
      mods << "E" if(line[i] == 32)
      # owner
      j = i
      i += 1 while (line[i] != 9 && i < line.size)
      owner = line[j..(i-1)] if(i!=j)
    end
    #indentation
    while (line[i] == 9)
      t += 1 
      i += 1
    end  
    text = line[i..-1].strip
    [t,mods,owner,text]
  end

end


class MFileManager

   attr_reader :files
   
   def initialize
      @files = []
      @dirs = []
      readIni
   end

   def getDir(d)
      d.chomp!
      @dirs << d
      dir = Dir.new(d)
      dir.each do |file|
         if (file[-4..-1] == '.txt' and file[-11..-5] != 'actions')
            f = MFile.new(d+file)
            @files << f
         end
      end
   end
  
   def exportToFreeMind
      @files.each {|f| f.exportToFreeMind }
   end
   
   def export_actions
      @files.each {|f| f.export_actions }
   end

   def nb_total_actions
      @files.inject(0) {|sum, f| sum + f.nb_actions }
   end
   
   def readIni()
      dir = ''
      ini = File.new("ActionRetreiver.ini", "r")
      ini.each_line do |com|
         #puts com
         next if dir.strip.empty?
         c, arg1, arg2 = com.split
         case c
            when 'd'
               dir = arg
               puts "Parsing dir: #{dir}"
               getDir(dir)
            when 'c'
               puts "Copying #{dir+arg} to #{dir}"
               File.copy(arg1,arg2)
            else
               puts "unknown command: #{com}"
         end

      end
      ini.close
   end

end
