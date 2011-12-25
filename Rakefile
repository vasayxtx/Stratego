#coding: utf-8

require 'mongo'
require File.join(File.dirname(__FILE__), 'db', 'seeds')

connection = Mongo::Connection.new

DB_NAME = 'stratego'


task :clean do
  connection.drop_database DB_NAME
end

task :seed do
  connection.drop_database DB_NAME
  db = connection.db DB_NAME

  Seed.create_indexes db
  Seed.seed_all db
end

