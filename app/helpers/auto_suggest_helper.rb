# frozen_string_literal: true

module AutoSuggestHelper
  # A text field that suggests crops as you type, and a hidden field that holds the id of the one chosen. options: class,
  # required, and default (a crop to start with).
  def auto_suggest(resource, source, options = {})
    default = options[:default]&.persisted? ? options[:default] : resource.send(source)
    name = resource.class.name.downcase

    safe_join([
                auto_suggest_text_field(source, default, options),
                tag.noscript('Warning: Javascript must be available to search and match crops', class: 'text-warning'),
                tag.input(id: "#{name}_#{source}_id", class: 'auto-suggest-id', type: 'hidden', name: "#{name}[#{source}_id]",
                          value: default.try(:id))
              ], "\n")
  end

  private

  # The words the field says, as data for auto_suggest.js. The name chosen is put in where it says {name}.
  def auto_suggest_words
    %i(searching choose none unchosen).index_with { |key| t("auto_suggest.#{key}") }.merge(chosen: t('auto_suggest.chosen', name: '{name}'))
  end

  def auto_suggest_text_field(source, default, options)
    source_url = Rails.application.routes.url_helpers.send("search_#{source}s_path", format: :json)
    tag.input(id: source, class: ['auto-suggest', options[:class]], required: options[:required], type: 'text', value: default,
              placeholder: 'e.g. lettuce', data: { source_url:, **auto_suggest_words })
  end
end
