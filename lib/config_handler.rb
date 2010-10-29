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

  attr_accessor :url, :username, :clientname, :key, :hash_token, :config_name

  @configured = false

  @config = {}
  

#  def self.config_exists? config_name
#    @config_name = config_name
#    File.exist?(config_file)
#  end

  def initialize config_name
    @configured = false
    self.config_name = config_name

    puts "Loading configuration with name #{config_name}"
    puts "Loading configuration from file '#{config_file}'"

    unless File.exist?(config_file)      
      puts "Configuration File not found"
      return nil
    end
    
		config_file_txt = File.open(config_file, "r").read {}

    begin
      @config = eval(config_file_txt)

      self.url = @config[:url]
      self.username = @config[:username]
      self.clientname = clientname
      self.key = @config[:key]
      self.hash_token = @config[:hash_token]

      puts "The configuration manages the URL: #{self.url}"
    rescue
      puts "The configuration named #{config_name} is invalid. Run CONFIG again to correct."
      return nil
    end
    @configured = true
    puts "Configured URL is #{self.url}"
  end

  def self.setup_config config_name, url, username, plaintext_password
    config = {
      :url => url,
      :username => username,
      :key => "",
      :hash_token => ""
    }

    puts "CONFIG setup for configuration named: #{config_name}"
    
    dav = Net::DAV.new(config[:url], :curl => false)
    dav.verify_server = false
    dav.credentials(config[:username], plaintext_password)
    return nil if !dav.exists?('.')

    hash_pw = Digest::SHA1.hexdigest(plaintext_password)
    config[:hash_token] = hash_pw

    puts "CONFIG generated user URI:" + user_uri(config[:username])
    config[:key] = Digest::SHA1.hexdigest(user_uri(config[:username]) + hash_pw)

    unless File.exist?(config_directory)
      FileUtils.mkdir_p(config_directory)
      FileUtils.chmod(0700, config_directory)
    end

    File.open(config_file(config_name), "w") {|f| f.write(config.inspect) }
    FileUtils.chmod(0600, config_file(config_name))

    return ConfigHandler.new(config_name)
    
  end

  def self.config_file config_name
    config_directory + "/#{config_name}_config"
  end

  def config_file
    ConfigHandler.config_file config_name
  end

  def self.config_directory
    OsSupport.home_directory + "/.consected_client_apps/transfer2webdav"
  end

  def self.clientname
    OsSupport.whoami.chomp + "--" + `hostname`.chomp
  end

  def self.user_uri username
    'storedcredentials//' + clientname + '/' + username + '/' 
  end

  def user_uri
    ConfigHandler.user_uri(self.username)
  end

  def configured?
    @configured
  end
  
end
