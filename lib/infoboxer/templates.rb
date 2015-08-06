module Infoboxer
  # Templates are cool, powerful and undocumented. Sorry :(
  #
  # I do my best.
  module Templates
    %w[base set].each do |tmpl|
      require_relative "templates/#{tmpl}"
    end
  end
end
