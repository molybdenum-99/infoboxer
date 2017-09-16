# encoding: utf-8

module Infoboxer
  MAJOR = 0
  MINOR = 3
  PATCH = 0
  PRE = 'pre'.freeze # set to `nil` for normal releases
  VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join('.')
end
