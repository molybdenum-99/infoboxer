# encoding: utf-8
module Infoboxer
  module Tree
    require_relative 'tree/node'
    require_relative 'tree/nodes'

    %w[text compound inline
      image html paragraphs list template table ref
      document].each do |type|
      require_relative "tree/#{type}"
    end
  end
end
