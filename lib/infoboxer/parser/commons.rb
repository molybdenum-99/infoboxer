# encoding: utf-8
module Infoboxer
  class Parser
    module Commons
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
