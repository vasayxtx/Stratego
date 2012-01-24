#coding: utf-8

%w[
  eventmachine
  em-websocket-client
  json
  fiber
].each { |gem| require gem }
require File.join(File.dirname(__FILE__), '..', 'src', 'utils')

include Utils

class Client
  attr_reader :login, :passw
  attr_accessor :sid

  def initialize(login, passw)
    @login, @passw = login, passw
    @sid = nil
  end
end

class Tester
  HOST = 'localhost'
  PORT = 9001

  attr_reader :clients

  def initialize(cl_num, &b)
    @fb_senders = {}
    @fb_streams = {}

    @clients = Array.new(cl_num) do |i|
      Client.new *b.call(i)
    end

    @tests = []
    @tests << [[
      0,
      { 'cmd' => 'dropDB' },
      { 0 => { 'status' => 'ok' } }
    ]]

    init_fiber
  end

  def push_test(test)
    @tests << test
  end

  def init_fiber
    @fb = Fiber.new do
      @tests.each_with_index do |test, i|
        test.each do |t|
          cl_i = t[0]
          req = t[1]

          @resps_num = t[2].size

          @queue = {}
          @fb_senders[cl_i].transfer req

          Fiber.yield
         
          t[2].each_pair do |cl_j, exp_resp|
            resp = @queue[cl_j]
            if resp.has_key?('sid')
              @clients[cl_j].sid = resp.delete 'sid'
            end
            unless exp_resp == resp
              puts "TEST##{i}: ERROR"
              puts "USER: ##{cl_j}"
              puts "REQUEST: #{req}"
              puts "EXP_RESP:\n#{exp_resp}"
              puts "RESP:\n#{resp}"
              puts "Diff\n"
              exp_resp.each_pair do |k, v|
                puts "#{v}\n#{resp[k]}\n" unless v == resp[k]
              end
              puts "\n\n"
            end
          end
        end
        puts "TEST##{i}: OK" 
      end
      @fb_stop.resume
    end
  end
  private :init_fiber

  def run
    EM.run do
      @fb_stop = Fiber.new do 
        EM::stop_event_loop
      end

      c = 0
      @clients.size.times do |j|
        conn = EventMachine::WebSocketClient.connect("ws://#{HOST}:#{PORT}/")

        @fb_senders[j] = Fiber.new do |req|
          loop do
            if req.instance_of?(Hash) && @clients[j].sid
              req['sid'] = @clients[j].sid
            end
            if req['cmd'] == 'logout'
              @clients[j].sid = nil
            end
            conn.send_msg req.to_json
            req = @fb.transfer
          end
        end

        conn.callback do
          @fb.resume if (c += 1) == @clients.size
        end

        conn.stream do |msg|
          @queue.merge! j => JSON.parse(msg)
          @fb.resume if @queue.size == @resps_num
        end
      end
    end
  end
end

def make_test(t, &b)
  test = []
  t.clients.each_with_index do |cl, i|
    test << b.call(cl, i)
  end
  t.push_test(test)
end

def auth(t, cmd = 'signup')
  make_test(t) do |cl, i|
    resp = { i => {
      'status' => 'ok',
      'login' => cl.login
    } }
    0.upto(i-1) do |j|
      resp[j] = {
        'cmd' => 'addUserOnline',
        'login' => cl.login
      }
    end
    req = {
      'cmd' => cmd,
      'login' => cl.login,
      'password' => cl.passw
    }
    [i, req, resp]
  end
end

def logout(t)
  make_test(t) do |cl, i|
    resp = { i => { 'status' => 'ok' } }
    (i+1).upto(t.clients.size-1) do |j|
      resp[j] = {
        'cmd'=> 'delUserOnline',
        'login' => "User#{i}"
      }
    end
    req = { 'cmd' => 'logout' }
    [i, req, resp]
  end
end

