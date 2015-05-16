# encoding: utf-8
class Object
  if RUBY_VERSION < '2.0.0'
    def itself
      self
    end
  end
end
