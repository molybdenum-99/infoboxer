# encoding: utf-8

module Infoboxer
  class Parser
    module Template
      include Tree

      # NB: here we are not distingish templates like `{{Infobox|variable}}`
      # and "magic words" like `{{formatnum:123}}`
      # Just calling all of them "templates". This behaviour will change
      # in future, I presume
      # More about magic words: https://www.mediawiki.org/wiki/Help:Magic_words
      def template
        name = @context.scan_continued_until(/\||:|}}/) or
          @context.fail!('Template name not found')

        log "Parsing template #{name}"

        name.strip!
        vars = @context.eat_matched?('}}') ? Nodes[] : template_vars
        @context.traits.templates.find(name).new(name, vars)
      end

      def template_vars
        log 'Parsing template variables'

        num = 1
        res = Nodes[]

        guarded_loop do
          @context.next! while @context.eol?
          if @context.check(/\s*([^=}|<]+)\s*=\s*/)
            name = @context.scan(/\s*([^=]+)/).strip
            @context.skip(/\s*=\s*/)
          else
            name = num
            num += 1
          end
          log "Variable #{name} found"

          value = sanitize_value(long_inline(/\||}}/))

          # it was just empty line otherwise
          res << Var.new(name.to_s, value) unless value.empty? && name.is_a?(Numeric)

          log 'Variable value found'

          break if @context.eat_matched?('}}')
          @context.eof? and @context.fail!("Unexpected break of template variables: #{res}")
        end
        res
      end

      def sanitize_value(nodes)
        nodes.pop if (nodes.last.is_a?(Pre) || nodes.last.is_a?(Text)) && nodes.last.text =~ /^\s*$/ # FIXME: dirty!
        nodes
      end
    end
  end
end
