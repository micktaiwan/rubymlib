class Line
  
  attr_reader :nbline, :indent, :mods, :owner, :text
  attr_writer :text, :indent
  
  def initialize(nbl, i, m, o, t)
    @nbline = nbl
    @indent = i
    @mods = m
    @owner = o
    @text = t
    sanitize
  end

  def sanitize
    @text.strip!
    (0..@text.size-1).each do |i|
      @text[i] = 32 if(@text[i] > 127 || @text[i].chr == '"' || @text[i].chr == '&')
    end
  end

end
