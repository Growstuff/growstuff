# frozen_string_literal: true

require 'bluecloth'
require 'haml/filters/growstuff_markdown'

class Haml::Filters
  class EscapedMarkdown < Haml::Filters::Base
    def compile(text)
      Haml::Helpers.html_escape Haml::Filters::GrowstuffMarkdown.new.compile(text)
    end
  end

  # Register it as the handler for the :escaped_markdown HAML command.
  # The automatic system gives us :escapedmarkdown, which is ugly.
  Haml::Filters.registered[:escaped_markdown] ||= EscapedMarkdown
end
