# frozen_string_literal: true

require 'bluecloth'
require 'haml/filters/growstuff_markdown'

class Haml::Filters
  class EscapedMarkdown < Haml::Filters::GrowstuffMarkdown
    # def compile(text)
    #   Haml::Util.escape_html Haml::Filters::GrowstuffMarkdown.new.compile(text)
    # end
  end

  # Register it as the handler for the :escaped_markdown HAML command.
  # The automatic system gives us :escapedmarkdown, which is ugly.
  Haml::Filters.registered[:escaped_markdown] ||= EscapedMarkdown
end
