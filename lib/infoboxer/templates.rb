module Infoboxer
  module Templates
    %w[base set].each do |tmpl|
      require_relative "templates/#{tmpl}"
    end
  end
end
