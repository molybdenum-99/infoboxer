# encoding: utf-8
module Infoboxer
  module Navigation
    %w[lookup shortcuts sections].each do |nav|
      require_relative "navigation/#{nav}"
    end
    class Tree::Node
      include Lookup::Node
      include Shortcuts::Node
      include Sections::Node
    end

    class Tree::Nodes
      include Lookup::Nodes
      include Shortcuts::Nodes
      include Sections::Nodes
    end

    class ::Infoboxer::Document
      include Sections::Container
    end
  end
end
