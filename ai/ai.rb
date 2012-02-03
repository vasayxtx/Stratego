#coding: utf-8

%w[
  eventmachine
  em-websocket-client
  json
  yaml
  logger
].each { |gem_file| require gem_file }

class AiClient
  def self.run(host, port, ai_player, log_file)
    File.delete(log_file) if File.exist?(log_file)
    log = Logger.new(log_file)

    is_end = false

    EM.run do
      conn = EventMachine::WebSocketClient.connect("ws://#{host}:#{port}/")

      conn.callback do
        req = ai_player.start
        log.debug("Request: #{req}")
        conn.send_msg(req.to_json)
      end

      conn.stream do |data|
        resp = JSON.parse(data)

        log.debug("Response: #{resp}")

        status = resp.delete('status')
        if status != 'ok' || is_end
          log.close
          EM::stop_event_loop
        else
          unless resp.empty?
            req, sys_msg = ai_player.handle(resp)
            is_end = sys_msg == 'die!'
            log.debug("Request: #{req}")
            conn.send_msg(req.to_json)
          end
        end
      end

      conn.disconnect do
      end
    end
  end
end

class AiPlayer
  def initialize(user_opts, game)
    @login = user_opts['login']
    @passw = user_opts['password']
    @game = game

    @fb = Fiber.new do
      # Login
      req = Fiber.yield(cmd_login)
      @sid = req['sid']
       
      if @game['is_creator']
        # Create game
        Fiber.yield(cmd_create_game)
      end

      # Logout
      Fiber.yield([cmd_logout, 'die!'])
    end
  end

  def start
    @fb.resume
  end

  def handle(resp)
    @fb.resume(resp)
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

  def cmd_create_game
    {
      cmd: 'createGame',
      name: @game['name'],
      nameMap: @game['map'],
      nameArmy: @game['army']
    }
  end
end

config = YAML.load_file(ARGV[0] || 'config.yml')

ai_player = AiPlayer.new(
  config['user'],
  config['game']
)

AiClient.run(
  config['ws_server']['host'],
  config['ws_server']['port'],
  ai_player,
  config['log_file']
)

