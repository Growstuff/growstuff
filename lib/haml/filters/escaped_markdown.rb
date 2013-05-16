gem 'bluecloth'

module Haml::Filters::Escaped_Markdown
  include Haml::Filters::Base

  def render(text)
    bc = BlueCloth.new(text)
    return Haml::Helpers.html_escape bc.to_html
  end
end
