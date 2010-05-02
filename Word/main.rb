require '../MLib/TextPrompt.rb'
require '../MLib/word'

FILE1 = 'E:\yo1.doc'
FILE2 = 'E:\yo2.doc'

class TextPrompt

   def initialize
      @word = MSWord.new
   end

   def parse_command(c)
      case c
      when 'q' # quit
         return 'break'
     when 'm' # methods
         return 'break'
      when 'c' # compare
         puts 'comparing...'
         @word.compare(FILE1,FILE2)
         puts 'compare end'
      end
   end
   
   def destroy
      @word.quit
   end
   
end

begin
   tp = TextPrompt.new
   tp.start
ensure
   tp.destroy
end   
