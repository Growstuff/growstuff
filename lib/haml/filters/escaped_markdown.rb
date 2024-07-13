# frozen_string_literal: true

require 'bluecloth'
require 'haml/filters/growstuff_markdown'

class Haml::Filters
  class EscapedMarkdown < Haml::Filters::Markdown
    def compile(node)
      [:escape, true, super(node)]
    end
  end

  # Register it as the handler for the :escaped_markdown HAML command.
  # The automatic system gives us :escapedmarkdown, which is ugly.
  Haml::Filters.registered[:escaped_markdown] ||= EscapedMarkdown
end
