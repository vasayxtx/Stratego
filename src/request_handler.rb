#coding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
%w[command].each { |file| require file }

class RequestHandler
  CMDS = [ 
    #----- Dev -----
    'dropDB',

    #----- Auth -----
    'signup',
    'login',
    'logout', 

=begin
    #----- Maps -----
    'createMap',
    'editMap',
    'getListAllMaps',
    'getListMaps',
    'destroyMap',
    'getMapParams',

    #----- Armies -----
    'createArmy',
    'editArmy',
    'getListAllArmies',
    'getListArmies',
    'destroyArmy',
    'getArmyUnits',
    'getArmyUnitsMoveLengths',
    #----- Lobby -----
    #
    'getLogin',
    'getListUsersOnline',
    'createGame',
    'getGameParams',
    'joinGame',
    'leaveGame',
    'destroyGame',
    'getListAvailableGames',
    'getCreatedGame',
    'getStartedGame',

    #----- Game -----
    'getGamePlacement',
    'setPlacement',
    'getGameSituation',
    'makeMove',

    #----- Units -----
    'getAllUnits'
=end
  ]

  @@cmd_map = {}
  CMDS.each do |cmd| 
    @@cmd_map[cmd] = Kernel.const_get(
      "Cmd#{cmd.chr.upcase + cmd[1..cmd.size-1]}"
    )
  end

  def self.set_db(db_conn, db)
    @@db_conn, @@db = db_conn, db
    Cmd.set_db db_conn, db
  end

  def self.handle(req)
    begin
      if bad_request?(req)
        raise ResponseBadRequest, 'Incorrect json'
      end
      cmd = process_header req
      resp, extra_resp, reg = cmd.handle req
    rescue ResponseError => ex
      return {
        'status' => ex.status,
        'message' => ex.message
      }
    rescue Exception => ex
      return {
        'status' => 'internallError',
        #:message => 'Internal error on sever side. Maybe request contains illegal data'
        'message' => ex.message
      }
    end
    resp['status'] = 'ok'

    [resp, extra_resp, reg]
  end

  def self.bad_request?(req)
    req.each_value { |v| return true if v.nil? }
    false
  end
  private_class_method :bad_request?

  def self.process_header(req)
    unless req.has_key? 'cmd'
      raise ResponseBadCommand, "None field 'cmd' in the request"
    end
    cl_cmd = @@cmd_map[req['cmd']]
    if cl_cmd.nil?
      raise ResponseBadCommand, "Unknown command (#{req['cmd']}) in the request"
    end
    req.delete 'cmd'

    cl_cmd.new req
  end
  private_class_method :process_header
end
