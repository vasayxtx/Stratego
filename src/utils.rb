#coding: utf-8

module Utils
  def clone(obj)
    Marshal.load Marshal.dump(obj)
  end

  def h_slice(h, keys)
    h.select { |k, v| keys.include? k }
  end
end

