#coding: utf-8

#Basic exception class for fail response status. 
class ResponseError < StandardError
  attr_reader :status, :message

  def initialize(status, msg)
    @status = status
    @message = msg
  end
end

[
  'badRequest', #Class for response status "badRequest"
  'badCommand', #Class for response status "badCommand"
  'badAction',  #Class for response status "badAction"
  'badFieldLenght',
  'badFieldFormat',
  'badFieldUnique',
  'badFieldValue',
  'badMap'
].each do |st|
  cl_const = Object::const_set(
    "Response#{st.chr.upcase + st[1..st.size-1]}",
    Class.new(ResponseError)
  )
  cl_const.class_eval do 
    define_method(:initialize) { |msg| super(st, msg) }
  end
end
