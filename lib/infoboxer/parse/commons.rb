# encoding: utf-8
module Infoboxer
  module Parse
    module Commons
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

      def scan_until(scanner, after)
        res = ''
        loop do
          str = scanner.scan_until(/{{|\[\[|#{after}/)
          case scanner.matched
          when '{{'
            res << str
            res << scan_continued(scanner, /{{/, /}}/) << '}}'
          when '[['
            res << str
            res << scan_continued(scanner, /\[\[/, /\]\]/) << ']]'
          when after
            res << str
            break
          when nil
            # simple markup is auto-closed: '''something is implicitly
            # closed at the end of paragraph
            res << scanner.rest
            scanner.terminate
            break
          end
        end
        res.sub(/#{after}\Z/, '')
      end

      def scan_continued(scanner, before, after, next_lines = [])
        res = ''
        level = 1

        before_or_after = Regexp.union(before, after)

        loop do
          str = scanner.scan_until(before_or_after)
          res << str if str

          case scanner.matched
          when before
            level += 1
          when after
            level -= 1
            
            break if level.zero?
          when nil
            
            # not finished on this line, look at next
            next_lines.empty? and fail("Can't find #{after} for #{before}, #{res}")
            scanner << "\n" << next_lines.shift
          end
        end
        res.sub(/#{after}\Z/, '')
      end
    end
  end
end
