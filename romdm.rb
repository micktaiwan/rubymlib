#!/usr/bin/env ruby
# ruby object method discovery module

module ROMDM

  def discover(object)
    methods = object.public_methods - Object.methods
    puts "#{methods.size} methods for object #{object.to_s} of class #{object.class.name} < #{object.class.superclass.name}"
    #hash = Hash.new(Array.new)
    methods.each { |m|
      a = object.method("#{m.to_s}".to_sym).arity
      puts m.to_s+" "+a.to_s
      #hash[a] << m
      #puts hash[0].size
      }
    #hash.each { |a,m|
    #  puts "#{m.to_s} (#{a})"
    #  }  
    #puts hash.size
  end

end

#include ROMDM
#o = "hello"
#discover(o)

