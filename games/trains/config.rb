CONFIG = {
  
  :joy => { # joystick configuration
    :dev => '/dev/input/js0',
    :factor => (32000.0)
    },
  
  :log => { # log config (not used)
    :joy   => nil,
    :pos   => nil,
    :event => nil,
    :collision => nil,
    :camera => nil,
    :debug => nil
  },
  
  :mouse => {
    :speed_factor => 0.2
    },
  
  :draw => {
    :screen_width => 1000,
    :screen_height => 800,
    :point_size  =>6,
    :menu => false
    },
    
  :cam => {
    :follow => true,
    :rotate => 0    # distance of rotation, 0 = no rotation
    },
  
  :net =>  {
    :ip   => '86.205.143.119', # change
    :port => 4999,
    :name => "bob" # change. must be < 10 chars
    },
  
  :sim => {
    :speed_factor => 1
    }
  
}

