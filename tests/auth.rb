#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')

CLIENTS_NUM = 5

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

#Test1
#--------------------------------
req = {
  'cmd' => 'signup',
  'login' => '21',
  'password' => '1234567'
}
resp = {
  0 => {
    'status' => 'badFieldLenght',
    'message' => 'Length of login must be in 3..20 characters'
  }
}
t.push_test([[0, req, resp]])

#Test2
#--------------------------------
req = {
  'cmd' => 'signup',
  'login' => '$asdasd435!ewer #',
  'password' => '1234567'
}
resp = {
  0 => {
    'status' => 'badFieldFormat',
    'message' => 'Invalid format of login. It must contain only word characters (letter, number, underscore)'
  }
}
t.push_test([[0, req, resp]])

#Test3
#--------------------------------
req = {
  'cmd' => 'signup',
  'login' => 'User0',
  'password' => '1234'
}
resp = {
  0 => {
    'status' => 'badFieldLenght',
    'message' => 'Length of password must be in 6..255 characters'
  }
}
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
auth t

#Test5
#--------------------------------
logout t

#Test6
#--------------------------------
req = {
  'cmd' => 'signup',
  'login' => 'User0',
  'password' => '1234567'
}
resp = {
  0 => {
    'status' => 'badFieldUnique',
    'message' => 'Login is already in use'
  }
}
t.push_test([
  [0, req, resp]
])

#Test7
#--------------------------------
req = {
  'cmd' => 'login',
  'login' => 'kadabra',
  'password' => '1234567'
}
resp = {
  0 => {
    'status' => 'badAction',
    'message' => 'Incorrect login'
  }
}
t.push_test([
  [0, req, resp]
])

#Test8
#--------------------------------
req = {
  'cmd' => 'login',
  'login' => 'User0',
  'password' => '1234567'
}
resp = {
  0 => {
    'status' => 'badAction',
    'message' => 'Incorrect password'
  }
}
t.push_test([
  [0, req, resp]
])

#Test9
#--------------------------------
auth t, 'login'

#Test10
#--------------------------------
logout t

t.run

