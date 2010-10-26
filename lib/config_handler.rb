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

class ConfigHandler

  require File.dirname(__FILE__) + '/os_support'

  attr_accessor :url, :username, :clientname, :key, :hash_token


  @config = {}

  def self.config_exists?
    File.exist?(config_file)
  end

  def initialize
    return nil unless File.exist?(ConfigHandler.config_file)
		config_file_txt = File.open(ConfigHandler.config_file, "r").read {}
		@config = eval(config_file_txt)

    self.url = @config[:url]
    self.username = @config[:username]
    self.clientname = clientname
    self.key = @config[:key]
    self.hash_token = @config[:hash_token]
    
  end

  def self.setup_config args
    config = {
      :url => args[1].chomp,
      :username => args[2].chomp,
      :key => "",
      :hash_token => ""
    }

    dav = Net::DAV.new(config[:url], :curl => false)
    dav.verify_server = false
    dav.credentials(config[:username], args[3].chomp)
    return :could_not_connect if !dav.exists?('.')

    hash_pw = Digest::SHA1.hexdigest(args[3].chomp)
    config[:hash_token] = hash_pw

    puts "Generated user URI:" + user_uri(config[:username])
    config[:key] = Digest::SHA1.hexdigest(user_uri(config[:username]) + hash_pw)

    unless File.exist?(config_directory)
      FileUtils.mkdir(config_directory)
      FileUtils.chmod(0700, config_directory)
    end

    config_file_txt = File.open(config_file, "w") {|f| f.write(config.inspect) }
    FileUtils.chmod(0600, config_file)

    return ConfigHandler.new
    
  end

  def self.config_file
    config_directory + "/user_config"
  end

  def self.config_directory
    OsSupport.home_directory + "/.transfer2webdav"
  end

  def self.clientname
    OsSupport.whoami.chomp + "--" + `hostname`.chomp
  end

  def self.user_uri username
    'storedcredentials//' + clientname + '/' + username + '/' 
  end

  def user_uri
    ConfigHandler.user_uri self.username
  end
  
end
