# encoding: utf-8
module Infoboxer
  module Navigation
    #%w[lookup shortcuts sections].each do |nav|
      #require_relative "navigation/#{nav}"
    #end

    %w[lookup shortcuts].each do |nav|
      require_relative "navigation/#{nav}"
    end
    class Tree::Node
      include Lookup::Node
      include Shortcuts::Node
    end

    class Tree::Nodes
      include Lookup::Nodes
      include Shortcuts::Nodes
    end
  end
end
