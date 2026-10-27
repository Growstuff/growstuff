# frozen_string_literal: true

# TODO: Move this file/helper elsewhere, as it is used as a pre filter rather than plugging into the haml architecture
class Haml::Filters
  class GrowstuffMarkdown
    CROP_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(crop\)/
    MEMBER_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(member\)/
    MEMBER_AT_REGEX = /(?<!\\)(@\w+)/
    PLANTING_REGEX = /(?<!\\)\[([^\[\]]+?)\]\(planting:([\w-]+)\)/
    # A Flickr photo placed in a post: ![caption](photo:123) or ![caption](photo:123/half)
    PHOTO_REGEX = /^!\[([^\[\]]*)\]\(photo:(\d+)(?:\/(wide|half|pair))?\)[ \t]*$/
    MEMBER_COMBINED_REGEX = Regexp.union(MEMBER_REGEX, MEMBER_AT_REGEX)
    MEMBER_ESCAPE_AT_REGEX = /(?<!\\)\\(?=@\w+)/
    HOST = Rails.application.config.host

    def expand_crops!(text)
      # turn [tomato](crop) into [tomato](http://growstuff.org/crops/tomato)
      text.gsub!(CROP_REGEX) do
        crop_str = Regexp.last_match(1)
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', crop_str.downcase).first
        crop_link crop, crop_str
      end
      text
    end

    def expand_plantings!(text)
      # turn [my tomato](planting:skud-backyard-tomato) into [my tomato](/plantings/skud-backyard-tomato)
      text.gsub!(PLANTING_REGEX) do
        link_text = Regexp.last_match(1)
        planting = Planting.find_by(slug: Regexp.last_match(2))
        planting_link planting, link_text
      end
      text
    end

    # With figures, a photo becomes a figure (the post page). Without, it is left
    # out, as in a teaser, an RSS feed or an email, where a picture is not wanted.
    def expand_photos!(text, figures: false)
      text.gsub!(PHOTO_REGEX) do
        caption = Regexp.last_match(1)
        photo = Photo.find_by(id: Regexp.last_match(2))
        figures && photo ? photo_figure(photo, caption, Regexp.last_match(3) || 'wide') : ''
      end
      text
    end

    def photo_figure(photo, caption, size)
      h = ERB::Util.method(:html_escape)
      url = Rails.application.routes.url_helpers.photo_path(photo)
      caption = caption.strip
      html = +%(\n\n<div class="post-figure post-figure-#{size}">\n)
      html << %(<a href="#{h.call(url)}"><img src="#{h.call(photo.fullsize_url)}" alt="#{h.call(caption.presence || photo.title)}"></a>\n)
      html << %(<p class="post-figure-caption">#{h.call(caption)}</p>\n) if caption.present?
      html << "</div>\n\n"
    end

    def expand_members!(text)
      # turn [jane](member) into [jane](http://growstuff.org/members/jane)
      # turn @jane into [@jane](http://growstuff.org/members/jane)
      text.gsub!(MEMBER_COMBINED_REGEX) do
        member_str = Regexp.last_match(1) || Regexp.last_match(2)
        member = find_member(member_str)
        member_link(member, member_str)
      end

      text.gsub!(MEMBER_ESCAPE_AT_REGEX, '')
      text
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

    def planting_link(planting, link_text)
      if planting
        url = Rails.application.routes.url_helpers.planting_url(planting, only_path: true)
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
