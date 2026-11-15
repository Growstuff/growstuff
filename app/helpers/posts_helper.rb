# frozen_string_literal: true

module PostsHelper
  def post_language_options
    names = I18nData.languages.merge(localized_post_languages)
    options = Post::LANGUAGES.map do |code|
      [names.fetch(code.upcase).split(';').first.strip, code]
    end
    options.sort_by { |name, _code| name.downcase }
  end

  def post_stripped_tags(post, length: 300)
    truncate(strip_tags(markdownify(post.body)), length:)
  end

  private

  def localized_post_languages
    I18nData.languages(I18n.locale.to_s.tr('-', '_'))
  rescue I18nData::NoTranslationAvailable
    begin
      I18nData.languages(I18n.locale.to_s.split(/[-_]/).first)
    rescue I18nData::NoTranslationAvailable
      {}
    end
  end
end
