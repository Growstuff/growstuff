# frozen_string_literal: true

# TODO: Move this file/helper elsewhere, as it is used as a pre filter rather than plugging into the haml architecture
class Haml::Filters
  class GrowstuffMarkdown
    CROP_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(crop\)/
    MEMBER_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(member\)/
    MEMBER_AT_REGEX = /(?<!\\)(@\w+)/
    MEMBER_ESCAPE_AT_REGEX = /(?<!\\)\\(?=@\w+)/
    HOST = Rails.application.config.host

    def expand_crops!(text)
      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      text.gsub(CROP_REGEX) do
        crop_str = Regexp.last_match(1)
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', crop_str.downcase).first
        crop_link crop, crop_str
      end
    end

    def expand_members!(text)
      # turn [jane](member) into [jane](http://growstuff.org/members/jane)
      # turn @jane into [@jane](http://growstuff.org/members/jane)
      [MEMBER_REGEX, MEMBER_AT_REGEX].each do |re|
        text = text.gsub(re) do
          member_str = Regexp.last_match(1)
          member = find_member(member_str)
          member_link(member, member_str)
        end
      end

      text.gsub(MEMBER_ESCAPE_AT_REGEX, '')
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
        url = Rails.application.routes.url_helpers.crop_url(crop, only_path: true)
        "[#{link_text}](#{url})"
      else
        link_text
      end
    end

    def find_member(login_name)
      # Remove @ if present
      login_name = login_name[1..] if login_name.start_with?('@')
      Member.case_insensitive_login_name(login_name).first
    end
  end
end
