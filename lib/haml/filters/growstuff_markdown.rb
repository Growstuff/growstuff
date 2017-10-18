require 'bluecloth'

module Haml::Filters # rubocop:disable Style/ClassAndModuleChildren
  module GrowstuffMarkdown
    include Haml::Filters::Base

    def render(text)
      @expanded = text
      expand_crops!
      expand_members!
      BlueCloth.new(@expanded).to_html
    end

    private

    CROP_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(crop\)/
    MEMBER_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(member\)/
    MEMBER_AT_REGEX = /(?<!\\)(\@\w+)/
    MEMBER_ESCAPE_AT_REGEX = /(?<!\\)\\(?=\@\w+)/
    HOST = Growstuff::Application.config.host

    def expand_crops!
      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      @expanded = @expanded.gsub(CROP_REGEX) do
        crop_str = Regexp.last_match(1)
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', crop_str.downcase).first
        crop_link crop, crop_str
      end
    end

    def expand_members!
      # turn [jane](member) into [jane](http://growstuff.org/members/jane)
      # turn @jane into [@jane](http://growstuff.org/members/jane)
      [MEMBER_REGEX, MEMBER_AT_REGEX].each do |re|
        @expanded = @expanded.gsub(re) do
          member_str = Regexp.last_match(1)
          member = find_member(member_str)
          member_link(member, member_str)
        end
      end

      @expanded = @expanded.gsub(MEMBER_ESCAPE_AT_REGEX, '')
    end

    def member_link(member, link_text)
      if member
        url = Rails.application.routes.url_helpers.member_url(member, only_path: true)
        "[#{link_text}](#{url})"
      else
        link_text
      end
    end

    def crop_link(crop, link_text)
      if crop
        url = Rails.application.routes.url_helpers.crop_url(crop, host: HOST)
        "[#{link_text}](#{url})"
      else
        link_text
      end
    end

    def find_member(login_name)
      # Remove @ if present
      login_name = login_name[1..-1] if login_name.start_with?('@')
      Member.case_insensitive_login_name(login_name).first
    end
  end

  # Register it as the handler for the :growstuff_markdown HAML command.
  # The automatic system gives us :growstuffmarkdown, which is ugly.
  defined['growstuff_markdown'] = GrowstuffMarkdown
end
