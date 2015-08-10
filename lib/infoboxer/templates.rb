module Infoboxer
  # Templates are cool, powerful and undocumented. Sorry :(
  #
  # You'd need to understand them from [Wikipedia docs](https://en.wikipedia.org/wiki/Wikipedia:Templates)
  # and then use much of Infoboxer's goodness provided with {Templates}
  # separate module.
  module Templates
    %w[base set].each do |tmpl|
      require_relative "templates/#{tmpl}"
    end
  end
end
