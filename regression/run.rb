# encoding: utf-8
#
# It's just a simple script to run through a set of known complicated
# pages to see if all of them parsed at least without errors.
#
# Not under specs/ because of relatively long run
#
require 'bundler/setup'
$:.unshift 'lib'

require 'infoboxer'

Dir[File.expand_path('pages/*.wiki', File.dirname(__FILE__))].each do |f|
  start = Time.now
  begin
    Infoboxer::Parse.document(File.read(f))
    tm = Time.now - start
    puts '%s successfully parsed in %.3f' % [File.basename(f), tm]
  rescue Infoboxer::Parse::ParsingError => e
    tm = Time.now - start
    puts "%s: parsing error after %.3f: %s:\n\t%s" % [File.basename(f), tm, e.message, e.backtrace.first(5).join("\n\t")]
  rescue => e
    tm = Time.now - start
    puts "%s: error %s after %.3f: %s:\n\t%s" % [File.basename(f), e.class, tm, e.message, e.backtrace.first(5).join("\n\t")]
  end
end
