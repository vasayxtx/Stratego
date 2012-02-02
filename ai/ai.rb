#coding: utf-8

%w[
  eventmachine
  em-websocket-client
  json
  yaml
].each { |gem_file| require gem_file }

class AiClient
  def self.run(host, port, ai_player)
    EM.run do
      conn = EventMachine::WebSocketClient.connect("ws://#{host}:#{port}/")

      conn.callback do
        req = ai_player.start
        conn.send_msg(req.to_json)
      end

      conn.stream do |resp|
        req = ai_player.parse_response(JSON.parse(resp))
        if req == 'die'
          puts 'By!!'
          EM::stop_event_loop
        end

        conn.send_msg(req.to_json)
      end

      conn.disconnect do
      end
    end
  end
end

class AiPlayer
  def initialize(login, passw)
    @login, @passw = login, passw

    @fb = Fiber.new do
      req = Fiber.yield(cmd_login)
      @sid = req['sid']
      Fiber.yield(cmd_logout)
      Fiber.yield('die')
    end
  end

  def start
    @fb.resume
  end

  def parse_response(req)
    @fb.resume(req)
  end

  def cmd_login
    {
      cmd: 'login',
      login: @login,
      password: @passw
    }
  end

  def cmd_logout
    { cmd: 'logout', sid: @sid }
  end
end

config = YAML.load_file('config.yml')

ai_player = AiPlayer.new(
  config['user']['login'],
  config['user']['password']
)
AiClient.run(
  config['ws_server']['host'],
  config['ws_server']['port'],
  ai_player
)
