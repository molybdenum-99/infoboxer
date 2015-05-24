# encoding: utf-8
module Infoboxer
  class Nodes < Array
    def select(&block)
      Nodes[*super]
    end

    def reject(&block)
      Nodes[*super]
    end

    def sort_by(&block)
      Nodes[*super]
    end

    MAX_CHILDREN = 3
    
    def inspect
      if count > MAX_CHILDREN
        '[' + self[0...MAX_CHILDREN].map(&:inspect).join(', ') + " ...#{self.count - MAX_CHILDREN} more]"
      else
        super
      end
    end
  end
end
