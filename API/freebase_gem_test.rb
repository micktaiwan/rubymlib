#!/usr/bin/env ruby
require 'rubygems'
require 'freebase'


an_artist = Freebase::Types::Music::Artist.find(:first)
#puts an_artist.methods
puts an_artist.fb_type

