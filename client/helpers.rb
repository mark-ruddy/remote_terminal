require 'socket'
require 'etc'
require 'net/http'

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
    # Try both incase one is not installed
    `ifconfig`
  end

  def self.sysinfo
    result = ""
    result += "OS: " + RUBY_PLATFORM + "\n"
    result += "Architecture: " + `uname -m`
    result += "Hostname: " + Socket.gethostname + "\n"
    result += "User: " + Etc.getlogin
  end

  def self.wget(addr)
    if addr.start_with? 'http'
      return "Error: Remove the http(s) from URL"
    end

    parsed = addr.split('/')
    site = parsed[0]
    filepath = parsed[1..-1].join '/'
    filepath[0, 0] = '/'
    filename = parsed[-1]

    begin
      Net::HTTP.start(site) do |http|
        down = http.get(filepath)
        file = File.new(filename, 'w')
        file.write(down.body)
        file.close
      end
      return "Download of file #{filename} from #{site} successful"
    rescue Exception => e
      return "Download failed: #{e.message}"
    end
  end
end
