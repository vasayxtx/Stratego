#coding: utf-8

%w[
  sinatra/base
  em-websocket
  thin
  haml
  sass
  compass
  compass_twitter_bootstrap
  coffee-script
  json
  yaml
  mongo
].each { |gem| require gem }

$LOAD_PATH << File.dirname(__FILE__)
%w[
  request_handler
  response_status
  clients_container
].each { |src_f| require File.join('src', src_f) }

cnfg = YAML.load_file('configure.yml')

db_conn = Mongo::Connection.new
db = db_conn.db cnfg['db']['name']

RequestHandler.set_db(db_conn, db)
ClContainer.set_db(db_conn, db)

class App < Sinatra::Base
  configure do
    # Compass.configuration do |config|
    #   config.project_path = File.dirname(__FILE__)
    #   config.sass_dir = 'views/stylesheets'
    # end

    set :haml, :format => :html5
    # set :sass, Compass.sass_engine_options
  end

  # get "/javascripts/:name.js" do
  #   coffee :"javascripts/#{params[:name]}"
  # end

  # get "/javascripts/spine/:name.js" do
  #   coffee :"javascripts/spine/#{params[:name]}"
  # end

  # get "/stylesheets/:name.css" do
  #   content_type 'text/css', :charset => 'utf-8'
  #   sass :"stylesheets/#{params[:name]}"
  # end

  get '/' do
    haml :layout
  end
end

EventMachine.run do
  EventMachine::WebSocket.start(
    :host => cnfg['ws_server']['host'],
    :port => cnfg['ws_server']['port']
  ) do |ws|

    ws.onopen do
      puts "WebSocket connection open"
    end

    ws.onclose do
      puts "Connection closed"
      ClContainer.unreg_client_by_ws ws
    end

    ws.onmessage do |msg|
      puts msg
      begin
        resp, msg, reg = RequestHandler.handle JSON.parse(msg)

        puts "RESP: #{resp}"
        puts "MSG: #{msg}"
        puts "REG: #{reg}"

        unless reg.nil?
          if reg.has_key?('reg')
            ClContainer.reg_client ws, reg['reg']
          end
          if reg.has_key?('unreg')
            ClContainer.unreg_client_by_id reg['unreg']
          end
        end

        unless msg.nil? || msg.empty?
          a = [ws]
          (msg.select { |k, v| k != :all }).each_pair do |cl_id, cl_msg|
            w = ClContainer.get_ws_by_id(cl_id)
            w.send cl_msg.to_json
            a << w
          end

          if msg.has_key?(:all)
            ww = ClContainer.get_all_ws.select { |w| !a.include?(w) }
            ww.each { |w| w.send msg[:all].to_json }
          end
        end

      rescue Exception => ex
       resp = { 
          'status'  => 'badRequest',
          'message' => ex.message
          #'message' => 'Incorrect json'
        }
      end
      ws.send resp.to_json
    end
  end

  App.run! :port => cnfg['app_server']['port']
end
