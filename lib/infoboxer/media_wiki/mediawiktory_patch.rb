require 'mediawiktory'

# FIXME: looks like pretty "core" functionality and should moved to mediawiktory itself

class MediaWiktory::Page
  attr_writer :queried_title

  def queried_title
    @queried_title || title
  end
end

class MediaWiktory::Query::Response
  alias_method :old_initialize, :initialize
  def initialize(*arg)
    old_initialize(*arg)
    
    if raw.query.redirects
      raw.query.redirects.each do |redirect|
        pg = @pages.detect{|p| p.title == redirect.to} or next
        pg.queried_title = redirect.from
      end
    end
  end
end
