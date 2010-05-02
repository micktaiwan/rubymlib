require 'win32ole'

class MSWord
   
   attr_reader :word

   def initialize
      @word = WIN32OLE.new('Word.Application')
   end

   def methods
      f = File.new('./m.txt','w')
      doc1 = @word.documents.item(1)
      f << doc1.ole_methods.join("\n")
      f.close
   end
   
   def compare(path1,path2)
      puts 'in Word: comparing...'
      @word.visible = true
      @word.documents.open(path1)
      doc1 = @word.documents.item(1)
      puts doc1.words.creator
      puts doc1.words.ole_methods
   end
   
   def quit
      @word.quit
   end
   

end
