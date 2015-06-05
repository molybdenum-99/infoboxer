# encoding: utf-8
module Infoboxer
  class Wikilink < Link
    def initialize(*)
      super
      parse_link!
    end
    attr_reader :name, :namespace, :anchor, :topic, :refinement

    private

    def parse_link!
      @name, @namespace = link.split(':', 2).reverse
      @namespace ||= ''

      @name, @anchor = @name.split('#', 2)
      @anchor ||= ''

      parse_topic!
    end

    # @see http://en.wikipedia.org/wiki/Help:Pipe_trick
    def parse_topic!
      @topic, @refinement = case @name
        when /^(.+\S)\s*\((.+)\)$/,
             /^(.+?),\s*(.+)$/
          [$1, $2]
        else
          [@name, '']
        end
    end
  end
end
