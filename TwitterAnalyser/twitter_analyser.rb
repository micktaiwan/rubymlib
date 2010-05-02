$: << File.expand_path(File.dirname(__FILE__) + '/../Mlib/')
require 'word_analyser'
require 'net/http'
require 'rexml/document'


class TwitterTrends < WordAnalyser

  URL = 'http://twitter.com/statuses/public_timeline.xml'
  
  def initialize
    super
  end

  def analyse
    #download
    @xml_data = File.open('twitter.xml').read
    doc = REXML::Document.new(@xml_data)
    doc.elements.each('statuses/status/text') do |e|
      add_text(e.text.downcase,'html')
      puts e.text
    end
    puts words_count.size
    top_list(0)
  end
  
  private

  def download
    @xml_data = Net::HTTP.get_response(URI.parse(URL)).body
    # just save a backup
    File.open('twitter.xml','w') {|f| f << @xml_data }
  end
  
end

TwitterTrends.new.analyse

