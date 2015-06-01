# encoding: utf-8
require_relative '../lib/infoboxer'

document = Infoboxer::Parser.parse(File.read('examples/pages/argentina.wiki'))

FileUtils.mkdir_p 'examples/output'

File.write('examples/output/argentina-text.txt', document.to_text)
