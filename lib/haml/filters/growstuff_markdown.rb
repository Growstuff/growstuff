require 'bluecloth'
include ActionDispatch::Routing
include Rails.application.routes.url_helpers

module Haml::Filters
  module GrowstuffMarkdown
    include Haml::Filters::Base

    def render(text)
      bc = BlueCloth.new(text)
      orig = bc.text

      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      return orig.gsub(/\[(.*?)\]\(crop\)/) do |m|
        crop_str = $1
        crop = Crop.find_by_system_name(crop_str)
        if crop
          url = url_for(crop_path(crop))
          "[#{crop_str}](#{url})"
        else
          crop_str
        end
      end
    end
  end

# Register it as the handler for the :growstuff_markdown HAML command.
# The automatic system gives us :growstuffmarkdown, which is ugly.
defined['growstuff_markdown'] = GrowstuffMarkdown

end
