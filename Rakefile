# coding: utf-8
require 'bundler/setup'
require 'infoboxer'
require 'rubygems/tasks'
Gem::Tasks.new

require 'yard-junk/rake'
YardJunk::Rake.define_task

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %w[spec rubocop yard:junk]

namespace :dev do
  desc "Run regression check (just parsed/error) on set of large and dirty pages"
  task :regression do
    Dir['regression/pages/*.wiki'].each do |f|
      start = Time.now
      text = File.read(f)
      begin
        Infoboxer::Parser.document(text)
        tm = Time.now - start
        puts '%s successfully parsed in %.3f' % [File.basename(f), tm]
      rescue Infoboxer::Parser::ParsingError => e
        tm = Time.now - start
        puts "%s: parsing error after %.3f: %s:\n\t%s" % [File.basename(f), tm, e.message, e.backtrace.first(5).join("\n\t")]
      rescue => e
        tm = Time.now - start
        puts "%s: error %s after %.3f: %s:\n\t%s" % [File.basename(f), e.class, tm, e.message, e.backtrace.first(5).join("\n\t")]
      end
    end
  end

  desc "Run profiling on several pages and dump results to HTML"
  task :profile do
    require 'ruby-prof'
    Dir['profile/pages/*.wiki'].each do |f|
      name = File.basename(f).sub('.wiki', '')
      out = "profile/out/#{name}.html"

      text = File.read(f)

      RubyProf.start

      Infoboxer::Parser.document(text)

      res = RubyProf.stop
      printer = RubyProf::GraphHtmlPrinter.new(res)

      printer.print(File.open(out, 'w'))

      puts '%s successfully parsed, see res: %s' % [File.basename(f), out]
    end
  end
end
