# encoding: utf-8
module Infoboxer
  class Parser
    module Template
      def template
        name = @context.scan_continued_until(/\||}}/) or
          @context.fail!("Template name not found")
          
        name.strip!
        vars = @context.eat_matched?('}}') ? Nodes[] : template_vars
        @context.traits.templates.find(name).new(name, vars)
      end

      def template_vars
        num = 1
        res = Nodes[]
        
        loop do
          if @context.check(/\s*([^ =}|]+)\s*=\s*/)
            name = @context.scan(/\s*([^ =]+)/).strip
            @context.skip(/\s*=\s*/)
          else
            name = num
          end

          value = long_inline(/\||}}/)
          unless value.empty? && name.is_a?(Numeric) # it was just empty line otherwise
            res << TemplateVariable.new(name.to_s, value)
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
