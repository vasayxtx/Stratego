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

cnfg = YAML.load_file 'configure.yml'

db_conn = Mongo::Connection.new
db = db_conn.db cnfg['db']['name']

RequestHandler.set_db db_conn, db
ClContainer.set_db db_conn, db

class App < Sinatra::Base
  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname __FILE__
      config.sass_dir = 'views/stylesheets'
    end

    set :haml, :format => :html5
    set :sass, Compass.sass_engine_options
  end

  get "/javascripts/:name.js" do
    coffee :"javascripts/#{params[:name]}"
  end

  get "/stylesheets/:name.css" do
    content_type 'text/css', :charset => 'utf-8'
    sass :"stylesheets/#{params[:name]}"
  end

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
      ClContainer.unreg_client ws
    end

    ws.onmessage do |msg|
      puts msg
      begin
        resp, extra_resp, reg = RequestHandler.handle JSON.parse(msg)

=begin
        puts "RESP: #{resp}"
        puts "EXTRA_RESP: #{extra_resp}"
        puts "REG: #{reg}"
=end

        unless reg.nil?
          if reg.has_key?('reg')
            ClContainer.reg_client ws, reg['reg']
          end
          if reg.has_key?('unreg')
            ClContainer.unreg_client_by_id reg['unreg']
          end
        end

        unless extra_resp.nil? || extra_resp.empty?
          if extra_resp.instance_of?(Hash)
            websockets = ClContainer.get_all_websockets
            websockets.each_key do |w|
              next if w == ws
              w.send extra_resp.to_json
            end
          else
            #extra_resp is instance of the Array class
          end
        end
      rescue Exception => ex
       resp = { 
          'status' => 'badRequest',
          'message' => ex.message
          #'message' => 'Incorrect json'
        }
      end
      ws.send resp.to_json
    end
  end

  App.run! :port => cnfg['app_server']['port']
end

