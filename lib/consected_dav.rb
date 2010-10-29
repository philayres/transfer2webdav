# Copyright 2010, Consected LLC, Massachusetts, USA.
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

class ConsectedDav 

  require 'net/dav'
  require 'uri'

  attr_accessor :delete
  @delete = false
  @dav = nil

  def initialize config
    puts "Connecting to #{config.url}"
    @dav = Net::DAV.new(config.url, :curl => false)
    @dav.verify_server = false
    puts "Connecting with user URI:" + config.user_uri
    @dav.credentials(config.user_uri, config.key)
  end


  def store_file path

    puts "Storing file #{path}"
    lines = File.open(path).read {}
    @dav.put_string(URI.escape(File.basename(path)), lines)
   	return :file_not_found if !File.exist?(path)
    puts "Stored file #{path}"
    return true
    
  end

  def transfer_directory path
    return :directory_not_found if !File.exist?(path) || !File.directory?(path)
    return :dav_subfolder_not_found if !@dav.exists?('.')    
    entries = Dir.entries(path)

    for fileentry in entries.sort do
      unless File.directory?(fileentry) || fileentry[0]=='.'
        store_file path+'/'+fileentry
        FileUtils.rm(path+'/'+fileentry) if @delete
        puts "STOREDIR saved file: #{fileentry}"
      end
    end

    return true

  end

  def subfolder=s    
    s = '/' if s.nil?
    s = '/' + s if s[0] != '/'
    s += '/' if s[-1] != '/'
    s = '.' + URI.escape(s)
    puts "Change subfolder to #{s}"
    @dav.cd s unless s == './'
  end

  def check_credentials
    true || @dav.exists?('.')
  end
  
end
