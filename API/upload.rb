#!/usr/bin/env ruby
# Taken from http://kfahlgren.com/blog/2006/11/01/multipart-post-in-ruby-2/

require 'rubygems'
require 'mime/types'
require 'net/http'
require 'cgi'

URL = "http://www.upndl.com/api/upload"
TIMEOUT_SECONDS = 5

class Param

  attr_accessor :k, :v
  
  def initialize( k, v )
    @k = k
    @v = v
  end

  def to_multipart
    return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"\r\n\r\n#{v}\r\n"
  end
end

class FileParam

  attr_accessor :k, :filename, :content
  
  def initialize( k, filename, content )
    @k = k
    @filename = filename
    @content = content
  end

  def to_multipart
    return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{filename}\"\r\n" +
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
  end
end

class MultipartPost
  BOUNDARY = 'flickrrocks-aaaaaabbbb0000'
  HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

  def prepare_query ( params )
    fp = []
    params.each do |k,v|
      if v.respond_to?(:read)
        fp.push(FileParam.new(k,v.path,v.read))
      else
        fp.push(Param.new(k,v))
      end
    end
    query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
    return query, HEADER
  end

end

def self.post_form(url, query, headers)
  Net::HTTP.start(url.host, url.port) {|con|
    con.read_timeout = TIMEOUT_SECONDS
    begin
      return con.post(url.path, query, headers)
    rescue => e
      puts "POSTING Failed #{e}... #{Time.now}"
    end
  }
end 


def do_it
  # Open the actually file I want to send
  path = ARGV[0]
  file = File.open(path, "rb")

  # set the params to meaningful values
  params = Hash.new
  params["file"]          = file
  params["mode"]          = ARGV[1]
  params["login"]         = ARGV[2]
  params["password"]      = ARGV[3]
  params["filePassword"]  = ARGV[4]

  # make a MultipartPost
  mp = MultipartPost.new

  # Get both the headers and the query ready,
  # given the new MultipartPost and the params
  # Hash
  query, headers = mp.prepare_query(params)
  # done with file now
  file.close

  # Do the actual POST, given the right inputs
  puts "Uploading #{path}..."
  url = URI.parse(URL)
  res = post_form(url, query, headers)

  # res holds the response to the POST
  case res
  when Net::HTTPSuccess
    puts "File uploaded succesfully"
  when Net::HTTPInternalServerError
    raise "Server returned a internal error"
  else
    raise "Unknown error #{res}: #{res.inspect}"
  end
end

raise "arguments are: file_path mode login pwd filepwd" if ARGV[0] == nil
do_it

