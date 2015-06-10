Gem::Specification.new do |s|
  s.name     = 'time_boots'
  s.version  = '0.0.1'
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/infoboxer'

  s.summary = 'Full wikipedia markup parser'
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.travis.yml
    )$/x
  end
  s.require_paths = ["lib"]

  s.add_dependency 'htmlentities'
  s.add_dependency 'procme'
  s.add_dependency 'rest-client'
  s.add_dependency 'addressable'
  s.add_dependency 'terminal-table'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'ruby-prof'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
