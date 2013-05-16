require 'bluecloth'

module Haml::Filters
  module EscapedMarkdown
    include Haml::Filters::Base

    def render(text)
      bc = BlueCloth.new(text)
      return Haml::Helpers.html_escape bc.to_html
    end
  end

# Register it as the handler for the :escaped_markdown HAML command.
# The automatic system gives us :escapedmarkdown, which is ugly.
defined['escaped_markdown'] = EscapedMarkdown

end
