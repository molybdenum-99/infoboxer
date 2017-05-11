source 'https://rubygems.org'

gemspec

# gem 'mediawiktory', github: 'molybdenum-99/mediawiktory', branch: 'develop'

group :docs do
  gem 'dokaz', git: 'https://github.com/zverok/dokaz.git'
  gem 'yard', '~> 0.9'
  gem 'redcarpet'
  #gem 'inch'
end

group :development do
  gem 'rake'
  gem 'ruby-prof'
  gem 'rubygems-tasks'
  gem 'byebug'
  gem 'rubocop'
end

group :test do
  gem 'rspec', '~> 3'
  gem 'rspec-its', '~> 1'
  gem 'vcr'
  gem 'webmock'
  gem 'saharspec', github: 'zverok/saharspec'
  gem 'coveralls', require: false
end
