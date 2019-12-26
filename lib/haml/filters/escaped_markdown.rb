# frozen_string_literal: true

require 'bluecloth'
require 'haml/filters/growstuff_markdown'

module Haml::Filters
  module EscapedMarkdown
    include Haml::Filters::Base
    def render(text)
      Haml::Helpers.html_escape Haml::Filters::GrowstuffMarkdown.render(text)
    end
  end

  # Register it as the handler for the :escaped_markdown HAML command.
  # The automatic system gives us :escapedmarkdown, which is ugly.
  defined['escaped_markdown'] = EscapedMarkdown
end
