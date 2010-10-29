#!/usr/bin/env ruby
#    Copyright 2010, Consected LLC, Massachusetts, USA.
#
#    This file is part of transfer2webdav.
#
#    transfer2webdav is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    transfer2webdav is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with transfer2webdav.  If not, see <http://www.gnu.org/licenses/>.



require 'rubygems'
require 'net/dav'
require 'digest/sha1'
require 'em-dir-watcher'
require File.dirname(__FILE__) + '/config_handler'
require File.dirname(__FILE__) + '/consected_dav'
require File.dirname(__FILE__) + '/os_support'


if ARGV.length == 0
	puts "Usage: STORE, STOREDIR, CONFIG, MONITOR"
	exit -10
end

config_name = nil
config_name = ARGV[1].chomp unless ARGV[1].nil?


@config = ConfigHandler.new(config_name)

if (@config.nil? || !@config.configured?) && ARGV[0] != 'CONFIG'
		puts "No configuration available. Please run the program again, entering CONFIG 'configuration_name' 'url' 'username' 'password'"
		exit -2
end



if ARGV[0] == 'STORE'
	if ARGV.length < 3
		puts "STORE call incorrect. Please run the program again: STORE 'configuration_name' 'filename' {'subfolder'}"
		exit -3
	end

	dav = ConsectedDav.new(@config)
  
  dav.subfolder=ARGV[3] unless ARGV[3].nil?
	path = ARGV[2]

  res = dav.store_file(path)

  if res==:file_not_found
  	puts "STORE file not found"
		exit -7
  elsif res
    puts "STORE save file '#{path}' successfully"
    exit 1
  end

elsif ARGV[0] == 'STOREDIR'
	if ARGV.length < 2 || ARGV[1].chomp == ""
		puts "STOREDIR call incorrect. Please run the program again, with arguments STOREDIR 'configuration_name' 'localdirectory' 'webdavsubfolder' {DELETE}"
		exit -3
	end

	dav = ConsectedDav.new(@config)

  path = ARGV[2]
  subfolder = ARGV[3]
  dav.subfolder = subfolder
  dav.delete = true if ARGV[4] == 'DELETE'

  puts "STOREDIR files in directory '#{path}' to subfolder #{subfolder}"
  dav.transfer_directory path

  
  if res==:directory_not_found    	
		puts "STOREDIR directory not found"
		exit -8
  elsif res==:directory_not_found
    puts "STOREDIR WebDAV subfolder not found"
		exit -11
  elsif res==:ok
    puts "STOREDIR saved files in directory '#{path}' successfully"
    exit 1
  end
elsif ARGV[0] == 'MONITOR'
	if ARGV.length < 3
		puts "MONITOR call incorrect. Please run the program again, with arguments MONITOR 'configuration_name' 'localdirectory' {'webdavsubfolder'}"
		exit -3
	end

  dav = ConsectedDav.new(@config)
  path = ARGV[2]
  subfolder = ARGV[3]
  dav.subfolder = subfolder

  puts "MONITOR directory #{path}, storing to subfolder #{subfolder}. \n
Will transfer to URL #{@config.url}\n
Starting by transferring all existing files in the local directory then sitting and monitoring for changes"
  puts "*** DELETING FILES AFTER TRANSFER ***"

  res = OsSupport.watch_dir_for_changes(path, dav)


  if :directory_not_found
		puts "MONITOR directory not found"
		exit -8
  elsif :exited_normally
    puts "MONITOR exited normally"
    exit 1
  end


elsif ARGV[0] == 'CONFIG'
	if ARGV.length < 4 
		puts "CONFIG call incorrect. Please run the program again, entering CONFIG 'configuration_name' 'url' 'username' 'password'"
		exit -3
	end

  url = ARGV[2]
  username = ARGV[3]
  plaintext_password = ARGV[4]

  puts "CONFIG will setup configuration with name #{config_name} with URL '#{url}'"

  @config = ConfigHandler.setup_config(config_name, url, username, plaintext_password)
  if @config.nil? || !@config.configured?
      puts "CONFIG tested the connection with the username and password supplied and could not connect to the WebDAV server. The details were not saved."
      exit -4
  end

  dav = ConsectedDav.new(@config)

  if dav.nil? || !dav.check_credentials
    puts "CONFIG completed but when testing the configuration could not connect to the specified URL with username and password supplied."
    exit -2
  else
    puts "CONFIG completed successfully."
    exit 1
  end
else
  puts "Unknown command as the first argument. Try again with STORE, STOREDIR, MONITOR or CONFIG"
  exit -99
end



