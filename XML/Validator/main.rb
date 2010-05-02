# see http://codeidol.com/other/rubyckbk/XML-and-HTML/Validating-an-XML-Document/

require 'rubygems'
require 'xml/libxml' # gem install libxml-ruby
# caution require 'libxml' works, but then the following code does not... 

xml = XML::Document.file('./example.xml')
s   = XML::Schema.new('./example.xsd')

xml.validate_schema(s)

#puts XML::Schema.public_methods.sort