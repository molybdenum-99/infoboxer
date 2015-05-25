# encoding: utf-8
require 'bundler/setup'
$:.unshift 'lib'

require 'infoboxer'
require 'ruby-prof'

RubyProf.start

Infoboxer::Parser.parse(File.read('profile/pages/argentina.txt'))

res = RubyProf.stop
printer = RubyProf::GraphHtmlPrinter.new(res)

printer.print(File.open('profile/out/profile-argentina.html', 'w'))
