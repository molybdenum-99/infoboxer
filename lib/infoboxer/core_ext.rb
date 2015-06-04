# encoding: utf-8
class Object
  if RUBY_VERSION < '2.2.0'
    def itself
      self
    end
  end
end

class Hash
  def except(*keys)
    reject{|k, v| keys.include?(k)}
  end
end
