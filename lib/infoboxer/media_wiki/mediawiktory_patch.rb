require 'mediawiktory'

# FIXME: looks like pretty "core" functionality and should moved to mediawiktory itself

#class MediaWiktory::Page
  #def alt_titles
    #@alt_titles ||= [title]
  #end
#end

#class MediaWiktory::Query::Response
  #alias_method :old_initialize, :initialize
  #def initialize(*arg)
    #old_initialize(*arg)

    #return unless raw.query.redirects
    #raw.query.redirects.each do |redirect|
      #pg = @pages.detect { |p| p.title == redirect.to } or next
      #pg.alt_titles << redirect.from
    #end
  #end
#end
