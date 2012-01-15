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
units = {}
Generator::UNITS.each_pair do |u, p|
  units[u] = {
    'rank'        => p[0],
    'moveLength'  => p[1],
    'minCount'    => p[2].min,
    'maxCount'    => p[2].max,
  }
end
resp = {
  0 => {
    'status' => 'ok',
    'units' => units
  }
}
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

