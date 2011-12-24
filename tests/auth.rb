#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')

CLIENTS_NUM = 10

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

auth t

t.run

