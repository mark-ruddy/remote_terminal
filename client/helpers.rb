require 'socket'
require 'etc'

module Helpers
  def self.exe(cmd)
    # `` executes bash command in Ruby
    `#{cmd}`
  end

  def self.ls
    `ls`
  end

  def self.pwd
    Dir.pwd
  end

  def self.pid
    Process.pid
  end

  def self.ifconfig
    # With || 'ip a' will run if 'ifconfig' is not installed
    `ifconfig || ip a`
  end

  def self.system
    result = "OS: " + RUBY_PLATFORM + "\n"
    result += "Architecture: " + `uname -m`
    result += "Hostname: " + Socket.gethostname + "\n"
    result += "User: " + Etc.getlogin
  end
end
