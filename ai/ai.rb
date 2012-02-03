#coding: utf-8

%w[
  eventmachine
  em-websocket-client
  json
  yaml
  logger
].each { |gem_file| require gem_file }

#--------------- Ai Client ---------------

class AiClient
  def self.run(host, port, ai_player, log_file)
    File.delete(log_file) if File.exist?(log_file)
    log = Logger.new(log_file)

    is_end = false
    sync_resp = nil

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
        if (status && status != 'ok') || is_end
          log.close
          EM::stop_event_loop
        elsif sync_resp.nil? || sync_resp == resp['cmd']
          sync_resp = nil
          req, opts = ai_player.handle(resp)

          unless opts.nil?
            if opts == 'die!'
              is_end = true
            else
              sync_resp = opts
            end
          end

          log.debug("Request: #{req}")
          conn.send_msg(req.to_json)
        end
      end

      conn.disconnect do
      end
    end
  end
end

#--------------- Ai Player ---------------

class AiPlayer
  def initialize(user_opts, game)
    @login = user_opts['login']
    @passw = user_opts['password']
    @is_creator = user_opts['is_creator']
    @game = game

    @fb = Fiber.new do
      # Login
      resp = Fiber.yield(cmd_login)
      @sid = resp['sid']
       
      if @is_creator
        # Create game
        Fiber.yield(cmd_create_game, 'startGamePlacement')
      else
        Fiber.yield(cmd_join_game)
      end

      # Logout
      Fiber.yield([cmd_logout, 'die!'])
    end
  end

  def start
    @fb.resume
  end

  def handle(resp)
    req, opts = @fb.resume(resp)
    req[:sid] = @sid if @sid

    [req, opts]
  end

  #--------- Commands ---------

  def cmd_login
    {
      cmd: 'login',
      login: @login,
      password: @passw
    }
  end

  def cmd_logout
    { cmd: 'logout' }
  end

  def cmd_create_game
    {
      cmd: 'createGame',
      name: @game['name'],
      nameMap: @game['map'],
      nameArmy: @game['army']
    }
  end

  def cmd_destroy_game
    { cmd: 'destroyGame' }
  end

  def cmd_join_game
    { cmd: 'joinGame', name: @game['name'] }
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
