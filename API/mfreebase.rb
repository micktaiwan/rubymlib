#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'net/http'

class FreebaseApi

  def metaweb_read(envelope)

    base_url = 'http://www.freebase.com/api/service/mqlread'
    url = "#{base_url}#{URI.encode(envelope)}"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body

    # we convert the returned JSON data to native Ruby
    # data structure - a hash
    result = JSON.parse(data)

    # if the code key indicates an error, we raise an error
    if result['code'] == '/api/status/error'
      raise "web service error #{url}"
    end
    
    result
  end

  def what_is(name)
    e = '?queries={"qname":{"query":[{"name" : "'+name+'","type": [] }]}}'
    metaweb_read(e)
  end

  def format_result(r)
    display_hash(r)
  end
  
private

  def display_array(a,t=0)
    puts "(Array) #{a.size} ["
    a.each { |i|
      print " "*(t*3)
      if i.class.to_s == "Hash"
        puts "(Hash)"
        display_hash(i, t+1)
      elsif i.class.to_s == "Array"
        display_array(i, t+1)
      else
        puts "(#{i.class}) #{i}"
      end   
      }
      print " "*(t*3)
      puts "]"
  end

  def display_hash(h,t=0)
    h.each {|k,v|
      print " "*(t*3)
      if v.class.to_s == "Hash"
        puts "#{k} => (Hash)"
        display_hash(v, t+1)
      elsif v.class.to_s == "Array"
        print "#{k} => "
        display_array(v, t+1)
      else
        puts "#{k} => (#{v.class}) #{v}"
      end   
      }
  end
end

fb = FreebaseApi.new
r = fb.what_is('openmoko')
fb.format_result(r)

