# encoding: utf-8
module Infoboxer
  class Parser
    module Template
      include Tree
      
      # NB: here we are not distingish templates like {{Infobox|variable}}
      # and "magic words" like {{formatnum:123}}
      # Just calling all of them "templates". This behaviour will change
      # in future, I presume
      # More about magic words: https://www.mediawiki.org/wiki/Help:Magic_words
      def template
        name = @context.scan_continued_until(/\||:|}}/) or
          @context.fail!("Template name not found")
          
        name.strip!
        vars = @context.eat_matched?('}}') ? Nodes[] : template_vars
        @context.traits.templates.find(name).new(name, vars)
      end

      def template_vars
        num = 1
        res = Nodes[]
        
        guarded_loop do
          @context.next! while @context.eol?
          if @context.check(/\s*([^ =}|]+)\s*=\s*/)
            name = @context.scan(/\s*([^ =]+)/).strip
            @context.skip(/\s*=\s*/)
          else
            name = num
          end

          value = long_inline(/\||}}/)
          unless value.empty? && name.is_a?(Numeric) # it was just empty line otherwise
            res << Var.new(name.to_s, value)
          end

          break if @context.eat_matched?('}}')
          @context.eof? and @context.fail!("Unexpected break of template variables: #{res}")

          num += 1
        end
        res
      end
    end
  end
end
