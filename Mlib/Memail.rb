#!/usr/bin/ruby1.8

require "net/smtp"
require "getoptlong"

# File:    CyOSendMimeMailSmtp.rb
# Author:  Oliver Mensinger
# Version: 2002-01-22
# Status:  Usable and stable for simple mails (incl. binary attachm.)
#
# Description:
# Create Mime mail with text and attachments and send it via SMTP
#
# Changes:
# 2002-01-22 After Ian reported a problem, the mail server address is now given
#            to Net::SMTP::new instead to Net:SMTP::start
#
# Supported functions: text part, binary attachments read from file
# To do: html part, binary attachment given to method as parameter, several recipients (cc, bcc)

class CyOSendMimeMailSmtp
  attr_accessor :text, :server, :from, :to, :subject

  def initialize()
    @boundary = createBoundary()
    @attachments = []  # or Array.new, attachments are stored in an array, each index is an hash (see attach method)
    @server = ""
    @subject = ""
    @from = @to = @text = ""
  end

  def createBoundary()
    return "----=_CyOSendMimeMailSmtp_Part_" + uniqueNumber()
  end

  private :createBoundary

  # create an unique number, length variables

  def uniqueNumber()
    return sprintf("%02X", rand(99999999 - 10000000) + 10000000) +  # random part
      sprintf("%02X", Time.new.to_i) +  # machine time
      sprintf("%02X", $$) +  # process number
      sprintf("%02X", Time.new.usec())  # micro seconds of machine
  end

  private :uniqueNumber

  # attachBinaryFile(phy_filename, real_filename = "")
  # adds a file and converts it to base64
  # phy_filename is the physical filename (incl. path) of a file that must exist
  # real_filename will be the name of the file in the mail message
  # if real_filename _is not given_, it will be the physical filename
  # returns true if file exists and was attached to mail, otherwise false

  def attachBinaryFile(phy_filename, real_filename = "name_of_attachment.pdf")
    # read file into string and convert it to base64
    begin
      f = File.new(phy_filename);
      data = f.read()
      f.close()
    rescue
      return false
    end

    data = [data].pack("m*");

    real_filename = phy_filename if real_filename == ""

    # the very special problem of phy_filename and real_filename:
    # the physical filename could by something like /tmp/12367672647342342,
    # as an external binary file stored outside of a database, where the
    # real filename is the original filename which is stored in the database.
    # so we take the real_filename for determining the files type
    attachment = { "type" => contentType(real_filename), "name" => File.basename(real_filename), "data" => data }
    @attachments.push(attachment)
  end

  def contentType(filename)
    filename = File.basename(filename).downcase
    if filename =~ /\.jp(e?)g$/ then return "image/jpg" end
    if filename =~ /\.gif$/ then return "image/gif" end
    if filename =~ /\.htm(l?)$/ then return "text/html" end
    if filename =~ /\.txt$/ then return "text/plain" end
    if filename =~ /\.zip$/ then return "application/zip" end
    if filename =~ /\.pdf$/ then return "application/pdf" end
    if filename =~ /\.doc$/ then return "application/msword" end
    # more types?!
    return "application/octet-stream"
  end

  private :contentType

  def sendMail()
    raise "mail server not specified" if @server.length == 0
    raise "sender address not specified" if @from.length == 0
    raise "receiver address not specified" if @to.length == 0
    #raise "nothing to send" if (@text.length == 0) && (@attachments.length == 0)

    smtp = Net::SMTP.new(@server)
    smtp.start('localhost')
    smtp.ready(@from, @to) do |wa|
      wa.write("From: #{@from}\r\n")
      wa.write("To: #{@to}\r\n")
      wa.write("Subject: #{@subject}\r\n")
      wa.write("MIME-Version: 1.0\r\n")
      # add multipart header if we have got attachments
      if (@attachments.length > 0)
        wa.write("Content-Type: multipart/mixed; boundary=\"#{@boundary}\"\r\n")
        wa.write("\r\n")
        wa.write("This is a multi-part message in MIME format.\r\n")
        wa.write("\r\n")
      end

      # add text part if given
      if (@text.length > 0)
        # add boundary if we are multiparted, otherwise just add text
        if (@attachments.length > 0)
          wa.write("--#{@boundary}\r\n")
          wa.write("Content-Type: text/plain; charset=\"iso-8859-1\"\r\n")
          wa.write("Content-Transfer-Encoding: 8bit\r\n")  # we don't take care of very old mail servers with 7 bit only
        else
          # if only text and no attachm. we give the encoding
          wa.write("Content-Type: text/plain; charset=iso-8859-1\r\n")
          wa.write("Content-Transfer-Encoding: 8bit\r\n")
        end
        wa.write("\r\n")
        wa.write("#{@text}\r\n")
        wa.write("\r\n")
      end

      # add attachments if given
      if (@attachments.length > 0)
        @attachments.each do |part|
          wa.write("--#{@boundary}\r\n")
          wa.write("Content-Type: #{part['type']}; name=\"#{part['name']}\"\r\n")
          wa.write("Content-Transfer-Encoding: base64\r\n")
          wa.write("Content-Disposition: attachment; filename=\"#{part['name']}\"\r\n")
          wa.write("\r\n")
          wa.write("#{part['data']}")  # no more need for \r\n here!
          wa.write("\r\n")
        end
      end

      # closing boundary if multiparted
      wa.write("--#{@boundary}--\r\n") if (@attachments.length > 0)
    end  # smtp.ready(...)
  end  # def sendMail()
end  # class CyOSendMimeMailSmtp

#=begin
  # example for using CyOSendMimeMailSmtp class
  #require "CyOSendMimeMailSmtp.rb"

  tos = []
  File.readlines('list_of_emails_test.txt').each {|line| tos.push(line.chomp!)}

  tos.each do |t|
    mail = CyOSendMimeMailSmtp.new()
    mail.server  = "localhost"
    mail.from    = "mickael@easyplay.com.tw"
    mail.to      = t
    mail.subject = "Test"
    mail.text    = %Q[Please find a test]
#宇展科技預定於2006年04月22日全面更換郵件伺服器
    if (!mail.attachBinaryFile("D:\\chu\\important\\easyplay.doc","easyplay.doc"))
      puts "could not attach file"
    end

    begin
      mail.sendMail()
      puts t
    rescue
      puts "error on sending: #{$!}"
    end
  end
#=end  
