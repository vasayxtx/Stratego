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
require File.join('src', 'request_handler')
require File.join('src', 'response_status')

cnfg = YAML.load_file 'configure.yml'

db_conn = Mongo::Connection.new
db = db_conn.db cnfg['db']['name']
RequestHandler.set_db db_conn, db

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
    end

    ws.onmessage do |msg|
      puts msg
      begin
        resp = RequestHandler.handle JSON.parse(msg)
      rescue Exception => ex
       resp = { 
          'status' => 'badRequest',
          'message' => 'Incorrect json'
        }
      end
      ws.send resp.to_json
    end
  end

  App.run! :port => cnfg['app_server']['port']
end

