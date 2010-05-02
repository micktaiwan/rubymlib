require "test/unit"
require 'word_analyser'
require 'rexml/document'

class WordAnalyser_test < Test::Unit::TestCase
  
  def setup
    super
    @w = WordAnalyser.new
  end
 
  def test_basic
    @w.add_text("youpi les potos youpi",'test')
    assert(@w.words_count.size == 3,"word count failed (1)")
    assert(@w.words_count['youpi'] == 2,"word count failed (2)")
    assert(@w.words_ref['youpi'].size == 1,"word ref count failed (3)")
    @w.clear
    assert(@w.words_count.size == 0,"word count failed (4)")
  end

  def test_html
    @w.clear
    file = File.open('test.html')
    @w.add_text(file.read,'html')
    puts @w.words_count.size
    @w.top_list
  end

  def test_twitter
    data = File.open('twitter.xml').read
    doc = REXML::Document.new(data)
    doc.elements.each('rss/channel/item/title') do |e|
      @w.add_text(e.text,'html')
    end
    puts @w.words_count.size
    @w.top_list(0)
  end

end
