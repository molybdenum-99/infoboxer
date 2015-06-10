# encoding: utf-8
module Infoboxer
  class Parser
    module Util
      def parse_params(str)
        return {} unless str
        
        scan = StringScanner.new(str)
        params = {}
        loop do
          scan.skip(/\s*/)
          name = scan.scan(/[^ \t=]+/) or break
          scan.skip(/\s*/)
          if scan.peek(1) == '='
            scan.skip(/=\s*/)
            q = scan.scan(/['"]/)
            if q
              value = scan.scan_until(/#{q}/).sub(q, '')
            else
              value = scan.scan_until(/\s|$/)
            end
            params[name.to_sym] = value
          else
            params[name.to_sym] = name
          end
        end
        params
      end
    end
  end
end
