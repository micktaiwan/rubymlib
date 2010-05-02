require "ActionRetreiver"
require "../MLib/TextPrompt.rb"

class P < TextPrompt

   def initialize
      super
      @fm = MFileManager.new
      puts "#{@fm.files.size} files parsed, with #{@fm.nb_total_actions} actions"
   end
   
   
   def parse_command(c)
      case c
      when 'q'
         return 'break'
      when 'h'
         puts 'a: export actions'
         puts 'f: export to freemind'
      when 'f'
         @fm.export_to_freemind
         puts "Exported to Freemind"
      when 'a'
      	puts "Exporting actions...."
         @fm.export_actions
         puts "Finished"
      end
   end

end

puts 'Action Retreiver'
p = P.new
p.start

