# un test pour virer les tags
require 'rexml/document'
require 'rubygems'
require 'ferret'
include Ferret

index = Index::Index.new() # :analyser=>Analysis::StandardAnalyzer.new(Analysis::FULL_FRENCH_STOP_WORDS)


data = File.open('twitter.xml').read
doc = REXML::Document.new(data)
doc.elements.each('rss/channel/item/title') do |e|
   #puts e.text
   index << e.text
end

#puts index.field_infos

index.search_each('ok') do |id, score|
  puts "Document #{id} found with a score of #{score}"
end

