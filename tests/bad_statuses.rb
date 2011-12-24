#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')

CLIENTS_NUM = 1

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

req = ''
resp = {
  'status' => 'badRequest',
  'message' => 'Incorrect json'
}
t.push_test([
  [0, req, { 0 =>  resp }]
])

req = '{'
resp = {
  'status' => 'badRequest',
  'message' => 'Incorrect json'
}
t.push_test([
  [0, req, { 0 => resp }]
])

t.run

