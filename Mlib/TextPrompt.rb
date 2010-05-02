class TextPrompt

   def initialize
   end

   def start
      loop do
         print '>'
         c = gets.chomp!
         next if c == ''
         case parse_command(c)
         when 'break'
            break
         end
      end
      bye
   end
   
   def parse_command(c)
      puts 'parse_command has to be derived'
   end
   
   def bye
      puts 'Bye'
   end
   
end
