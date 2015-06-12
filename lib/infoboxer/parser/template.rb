# encoding: utf-8
module Infoboxer
  class Parser
    module Template
      def template
        name = @context.scan_continued_until(/\||}}/) or
          @context.fail!("Template name not found")
          
        name.strip!
        vars = @context.matched == '}}' ? {} : template_vars
        @context.traits.expand(Infoboxer::Template.new(name, vars))
      end

      def template_vars
        num = 1
        res = {}
        
        loop do
          if @context.check(/\s*([^ =]+)\s*=\s*/)
            name = @context.scan(/\s*([^ =]+)/).strip.to_sym
            @context.skip(/\s*=\s*/)
          else
            name = num
          end

          value = long_inline(/\||}}/)
          unless value.empty? && name.is_a?(Numeric) # it was just empty line otherwise
            res[name] = TemplateVariable.new(value)
          end

          break if @context.matched == '}}'
          @context.eof? and @context.fail!("Unexpected break of template variables: #{res}")

          num += 1
        end
        res
      end
    end
  end
end
