# encoding: utf-8
require 'bundler/setup'
$:.unshift 'lib'

require 'infoboxer'
require 'ruby-prof'

Dir[File.expand_path('pages/*.wiki', File.dirname(__FILE__))].each do |f|
  name = File.basename(f).sub('.wiki', '')
  out = "profile/out/#{name}.html"

  RubyProf.start

  Infoboxer::Parse.document(File.read(f))

  res = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(res)

  printer.print(File.open(out, 'w'))

  puts '%s successfully parsed, see res: %s' % [File.basename(f), out]
end
