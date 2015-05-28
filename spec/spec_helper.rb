# encoding: utf-8

require 'rspec/its'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

$:.unshift 'lib'

require 'infoboxer'
