#!/usr/bin/env ruby

# one way to do it

require "rubygems"
require "treetop"

Treetop.load "grammar"

parser  = GrammarParser.new

text = File.open('./test_court.txt').readlines.join
puts text

node    = parser.parse(text)

puts node.value


