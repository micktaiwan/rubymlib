class Control

  attr_accessor :input

  def initialize(i, r, m, f)
    @input      = i # could be a character, or an axis name, or anything
    @receivers  = r # the influenced objects instances (hopefully constraints)
    @method     = m # receiver's method to call with value
    @factor     = f # the value is modified by factor
  end
  
  def action(value)
    @receivers.each {|r| r.send(@method, value*@factor) }
  end
  
end

class Controls

  def initialize(j)
    @joy = j
    @controls = []
    @axis = Hash.new{0}
  end
  
  def <<(args)
    @controls << Control.new(args[0],args[1],args[2],args[3]) 
  end
  
  # receive a input and do the coresponding action
  def action(input, value)
    cs = find_by_input(input)
    cs.each { |c| c.action(value)}    
  end
  
  def find_by_input(i)
    @controls.select { |c| c.input == i} 
  end
  
  def joy
    @axis.each { |n,v|
      action("axis#{n}",v)
      }
    return if not @joy.joy.pending?
    ev = @joy.joy.ev
    case ev.type
    when Joystick::Event::BUTTON
      action("button#{ev.num}",1) if ev.val > 0
    when Joystick::Event::AXIS
      @axis[ev.num] = ev.val/CONFIG[:joy][:factor]
    end
  end
  
end

