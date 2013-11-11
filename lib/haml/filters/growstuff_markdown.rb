require 'bluecloth'

module Haml::Filters
  module GrowstuffMarkdown
    include Haml::Filters::Base

    def render(text)

      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      expanded = text.gsub(/\[(.*?)\]\(crop\)/) do |m|
        crop_str = $1
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', crop_str.downcase).first
        if crop
          url = Rails.application.routes.url_helpers.crop_url(crop, :host => Growstuff::Application.config.host)
          "[#{crop_str}](#{url})"
        else
          crop_str
        end
      end

      return BlueCloth.new(expanded).to_html

    end
  end

# Register it as the handler for the :growstuff_markdown HAML command.
# The automatic system gives us :growstuffmarkdown, which is ugly.
defined['growstuff_markdown'] = GrowstuffMarkdown

end
