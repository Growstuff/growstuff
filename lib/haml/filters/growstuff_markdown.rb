require 'bluecloth'

module Haml::Filters
  module GrowstuffMarkdown
    include Haml::Filters::Base

    def render(text)
      @expanded = text
      expand_crops
      expand_members
      BlueCloth.new(@expanded).to_html
    end

    private

    CROP_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(crop\)/
    MEMBER_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(member\)/
    MEMBER_AT_REGEX = /(?<!\\)(\@\w+)/
    MEMBER_ESCAPE_AT_REGEX = /(?<!\\)\\(?=\@\w+)/

    def expand_crops
      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      @expanded = @expanded.gsub(CROP_REGEX) do |m|
        crop_str = Regexp.last_match(1)
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', crop_str.downcase).first
        crop_link crop, crop_str
      end
    end

    def expand_members
      # turn [jane](member) into [jane](http://growstuff.org/members/jane)
      @expanded = @expanded.gsub(MEMBER_REGEX) do |m|
        member_str = Regexp.last_match(1)
        # find member case-insensitively
        member = Member.case_insensitive_login_name(member_str).first
        member_link(member, member_str)
      end

      # turn @jane into [@jane](http://growstuff.org/members/jane)
      @expanded = @expanded.gsub(MEMBER_AT_REGEX) do |m|
        member_str = Regexp.last_match(1)
        # find member case-insensitively
        member = Member.case_insensitive_login_name(member_str[1..-1]).first
        member_link(member, member_str)
      end

      @expanded = @expanded.gsub(MEMBER_ESCAPE_AT_REGEX, "")
    end

    def member_link(member, link_text)
      if member
        url = Rails.application.routes.url_helpers.member_url(member, only_path: true)
        "[#{link_text}](#{url})"
      else
        member_str
      end
    end

    def crop_link(crop, _link_text)
      if crop
        url = Rails.application.routes.url_helpers.crop_url(crop, host: Growstuff::Application.config.host)
        "[#{crop_str}](#{url})"
      else
        crop_str
      end
    end
  end

  # Register it as the handler for the :growstuff_markdown HAML command.
  # The automatic system gives us :growstuffmarkdown, which is ugly.
  defined['growstuff_markdown'] = GrowstuffMarkdown
end
