begin
require 'joystick'
rescue Exception=>e
  puts "Info: Joystick library is not installed"
  
  module Joystick
    class Device
      def initialize(device)
      end
      def fake
      end
    end
  end
end

class Joy

  attr_reader :joy
  
  def initialize(device)
    # open the joystick device
    begin
      @joy = Joystick::Device.new(device)
    rescue Exception => e
      @joy = nil
    end
    @present = (@joy != nil and not @joy.respond_to?(:fake))
  end
  
  def present?()
    @present
  end
    
end

if __FILE__ == $0

  j = Joy.new('/dev/input/js0')
  raise "joy not found" if not j.present?
  puts "name: "+j.joy.name
  puts "buttons: "+j.joy.buttons.to_s
  puts "axes: "+j.joy.axes.to_s

  #j.start_listening
  loop {
    next if not j.joy.pending?
    ev = j.joy.ev 
    case ev.type
    when Joystick::Event::INIT
      puts 'init'
    when Joystick::Event::BUTTON
      puts "button: #{ev.num}, #{ev.val/32000.0}"
    when Joystick::Event::AXIS
      puts "axis: #{ev.num}, #{ev.val/32000.0}"
    else
      puts "unknown event: #{ev.type}"
    end
    }
  j.destroy
  
end

