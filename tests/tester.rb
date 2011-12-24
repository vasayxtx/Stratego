#coding: utf-8

%w[
  eventmachine
  em-websocket-client
  json
  fiber
].each { |gem| require gem }

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
  end

  def push_test(test)
    @tests << test
  end

  def t_fiber
    Fiber.new do
      @fb_senders[0].transfer 'cmd' => 'dropDB'
      @fb_streams[0].transfer :exp_resp => { 'status' => 'OK' }

      @tests.each_with_index do |test, i|
        test.each do |t|
          cl_i = t[0]
          req = t[1]

          @fb_senders[cl_i].transfer req

          t[2].each do |exp_resps|
            @fb_streams[exp_resps[0]].transfer({
              :num => i,
              :exp_resp => exp_resps[1]
            })
          end
        end
        puts "TEST##{i}: OK"
      end
    end
  end

  def run
    EM.run do
      f = t_fiber

      c = 0
      @clients.size.times do |j|
        conn = EventMachine::WebSocketClient.connect("ws://#{HOST}:#{PORT}/")

        @fb_senders[j] = Fiber.new do |h|
          loop do
            if h.instance_of?(Hash) && @clients[j].sid
              h['sid'] = @clietns[j].sid
            end
            conn.send_msg h.to_json
            h = f.transfer
          end
        end

        @fb_streams[j] = Fiber.new do |test|
          loop do
            resp = Fiber.yield
            @clients[j].sid = resp.delete 'sid'
            unless test[:exp_resp] == resp
              puts "TEST##{test[:num]}: ERROR"
              puts "EXP_RESP:\n#{test[:exp_resp]}"
              puts "RESP:\n#{resp}"
              EM::stop_event_loop
            end
            test = f.transfer
          end
        end

        conn.callback do
          f.transfer if (c += 1) == @clients.size
        end

        conn.stream do |msg|
          @fb_streams[j].resume JSON.parse(msg)
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
    [
      i, 
      {
        'cmd' => cmd,
        'login' => cl.login,
        'password' => cl.passw,
      }, 
      [[
        i,
        { 'status' => 'OK' }
      ]]
    ]
  end
end

def logout(t)
end

