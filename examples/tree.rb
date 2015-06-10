# encoding: utf-8
require_relative '../lib/infoboxer'

document = Infoboxer::Parser.document(File.read('examples/pages/argentina.wiki'))

FileUtils.mkdir_p 'examples/output'

File.write('examples/output/argentina-tree.txt', document.to_tree)
