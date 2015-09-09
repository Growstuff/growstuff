require 'bluecloth'

module Haml::Filters
  module GrowstuffMarkdown
    CROP_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(crop\)/
    MEMBER_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(member\)/
    MEMBER_AT_REGEX = /(?<!\\)(\@\w+)/
    MEMBER_ESCAPE_AT_REGEX = /(?<!\\)\\(?=\@\w+)/
    include Haml::Filters::Base

    def render(text)

      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      expanded = text.gsub(CROP_REGEX) do |m|
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

      # turn [jane](member) into [jane](http://growstuff.org/members/jane)
      expanded = expanded.gsub(MEMBER_REGEX) do |m|
        member_str = $1
        # find member case-insensitively
        member = Member.where('lower(login_name) = ?', member_str.downcase).first
        if member
          url = Rails.application.routes.url_helpers.member_url(member, :only_path => true)
          "[#{member_str}](#{url})"
        else
          member_str
        end
      end

      # turn @jane into [@jane](http://growstuff.org/members/jane)
      expanded = expanded.gsub(MEMBER_AT_REGEX) do |m|
        member_str = $1
        # find member case-insensitively
        member = Member.where('lower(login_name) = ?', member_str[1..-1].downcase).first
        if member
          url = Rails.application.routes.url_helpers.member_url(member, :only_path => true)
          "[#{member_str}](#{url})"
        else
          member_str
        end
      end

      expanded = expanded.gsub(MEMBER_ESCAPE_AT_REGEX, "")

      return BlueCloth.new(expanded).to_html

    end
  end

# Register it as the handler for the :growstuff_markdown HAML command.
# The automatic system gives us :growstuffmarkdown, which is ugly.
defined['growstuff_markdown'] = GrowstuffMarkdown

end
