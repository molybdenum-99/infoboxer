module Infoboxer
  class WikiPath
    ParseError = Class.new(ArgumentError)

    class << self
      def _parse(string)
        scanner = StringScanner.new(string)
        res = []
        loop do
          res << scan_step(scanner)
          break if scanner.eos?
        end
        res
      end

      def parse(string)
        new(_parse(string))
      end

      private

      def scan_step(scanner)
        op = scanner.scan(%r{//?}) or unexpected(scanner, '/')
        type = scanner.scan(/[A-Za-z_]*/)
        attrs = {}
        while scanner.scan(/\[/)
          attr = scanner.scan(/[-a-z_0-9]+/) or unexpected(scanner, 'attribute name')
          if scanner.scan(/\]/)
            (attrs[:predicates] ||= []) << "#{attr}?".to_sym
            next
          end
          scanner.scan(/\s*=\s*/) or unexpected(scanner, '= or ]')
          value = scanner.scan(/[^\]]+/) # TODO: probably, should do a proper [] counting?..
          scanner.scan(/\]/) or unexpected(scanner, ']')
          attrs[attr.to_sym] = process_value(value)
        end
        res = op == '//' ? {op: :lookup} : {}
        res[:type] = type.gsub(/(?:^|_)([a-z])/, &:upcase).tr('_', '').to_sym unless type.empty?
        res.merge(attrs) # TODO: raise if empty selector
      end

      def process_value(value)
        case value
        when /^'(.*)'$/, /^"(.*)"$/
          Regexp.last_match(1)
        when %r{^/(.+)/$}
          Regexp.new(Regexp.last_match(1))
        else
          value
        end
      end

      def unexpected(scanner, expected)
        place = scanner.eos? ? 'end of pattern' : scanner.rest.inspect
        fail ParseError, "Unexpected #{place}, expecting #{expected}"
      end
    end

    def initialize(path)
      @path = path
    end

    def call(node)
      @path.inject(node) { |res, step| apply_step(res, step) }
    end

    private

    def apply_step(node, step)
      op = step.delete(:op) || :lookup_children
      args = []
      if (t = step.delete(:type))
        args << t
      end
      if (pred = step.delete(:predicates))
        args.concat(pred)
      end
      args << step unless step.empty?
      node.send(op, *args)
    end
  end
end
