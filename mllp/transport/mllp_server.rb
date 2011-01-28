require 'rubygems'
require 'eventmachine'

class MLLPServer
  attr_accessor :connections

  def initialize
    @connections = []
  end

  def start
    @signature = EM.start_server('0.0.0.0', 2100, MLLPConnection)
  end

  def stop
    EventMachine.stop_server(@signature)

    unless wait_for_connections_and_stop
      # Still some connections running, schedule a check later
      EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
    end
  end

  def wait_for_connections_and_stop
    if @connections.empty?
      EventMachine.stop
      true
    else
      puts "Waiting for #{@connections.size} connection(s) to finish ..."
      false
    end
  end
end

class MLLPConnection < EventMachine::Connection

  def post_init
    puts "-- Incoming Message --"
  end

  def receive_data data
    puts "Length :: #{data.length}"
    (@buf ||= '') << data
    if line = @buf.slice!(/\x1c/)
      puts "Message :: #{@buf.inspect}"
      send_data "\x0bHello World\x0d\x1c\x0d"
      @buf = ''
    end
  end

  def unbind
    puts "-- Connection Closed --"
  end
  
end

EM.run do
  server = MLLPServer.new
  server.start
end



