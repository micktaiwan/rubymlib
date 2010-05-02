Chat
====

A GTK test with ruby
Hopefully it will end in a full chat client :)

Current status: works (without user list for now)
I'm trying to build a multi protocol chat.
Adding IRC.

Ruby
====

sudo apt-get install ruby
or for Windows:
http://rubyinstaller.rubyforge.org/wiki/wiki.pl


Ruby GNOME (even for Windows)
=============================

The client needs ruby-gnome2:
http://ruby-gnome2.sourceforge.jp/

Install guides:
http://ruby-gnome2.sourceforge.jp/hiki.cgi?Install+Guide

Needed specifically for Windows users:
http://ruby-gnome2.sourceforge.jp/hiki.cgi?Install+Guide+for+Windows
Install...
http://prdownloads.sourceforge.net/ruby-gnome2/ruby-gnome2-0.16.0-1-i386-mswin32.exe?download
... in the ruby directory (or ruby files won't be copied in the ruby lib directory and ruby -e "require 'gtk2'" won't work)

On Linux: I don't remember: sudo apt-get install ruby-gnome or apt-get install libgtk2-ruby

