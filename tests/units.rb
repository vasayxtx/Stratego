#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'generator')

CLIENTS_NUM = 5

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

#Test1
#--------------------------------
auth t

#Test2
#--------------------------------
req = { 'cmd' => 'getAllUnits' }
foo = clone Generator::UNITS
foo.each_pair { |k, v| foo[k] = v[0..1] + [v[2].min, v[2].max] }
resp = {
  0 => {
    'status' => 'ok',
    'units' => foo
  }
}
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

