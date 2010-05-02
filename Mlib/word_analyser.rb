require File.dirname(__FILE__) + '/tokenizer'

class WordAnalyser
  
  attr_reader :words_count, :words_ref
  
  def initialize
    @words_count = Hash.new(0)
    @words_ref   = Hash.new([])
    @tokenizer = Tokenizer.new
  end
  
  # add a corpus, with an unique reference
  def add_text(text,ref)
    parse_corpus(text,ref)
    #@words_count.each { |w,c| puts "#{w}: #{c}"}
  end
  
  def clear
    @words_count.clear
    @words_ref.clear    
  end
  
  def top_list(count=25)
    i = 0
    @words_count.sort_by {|a,b| -b}.each {|a,b| puts "#{b}: #{a}"; i+=1; break if count > 0 and i > count}
  end
  
  private
  
  # read the corpus words
  def parse_corpus(text,ref)
    @tokenizer.parse(text).each {|w| add_word(w,ref)}
  end

  # add a word with the unique corpus ref
  def add_word(w,corpus_ref)
    @words_count[w] += 1
    @words_ref[w] << corpus_ref if not @words_ref[w].include?(corpus_ref)
    #puts "adding #{w} in #{corpus_ref}"
    #puts @words_ref.size
  end
  
end

