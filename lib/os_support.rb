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


class OsSupport

  require 'rubygems'
  require 'eventmachine'
  require 'em-dir-watcher'


  def self.is_windows?
    RUBY_PLATFORM =~ /(win|w)32$/
  end

  def self.whoami
    `echo %USERDOMAIN%\%USERNAME%` if is_windows?
    `whoami` unless is_windows?
  end

  def self.watch_dir_for_changes dirpath, dav

    if !File.exist?(dirpath) || !File.directory?(dirpath)
      return :directory_not_found
    end
    dav.delete = true

    return :error_starting_up if dav.transfer_directory(dirpath)!=true

    EM.run {
    dw = EMDirWatcher.watch dirpath, :grace_period => 5.0 do |paths|
        paths.each do |path|
            fullpath = dirpath + '/'+ path
            if File.exist?(fullpath)
                puts "New file: #{path}"
                dav.transfer_directory dirpath
            else
                puts "Deleted: #{path}"
            end
        end
    end
    }
    return :exited_normally
  end

  def self.home_directory
    #return ENV[:homedrive] + ENV[:homepath]  if is_windows?
    return File.expand_path('~')
  end

end
