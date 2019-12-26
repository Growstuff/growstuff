# frozen_string_literal: true

module AutoSuggestHelper
  def auto_suggest(resource, source, options = {})
    if options[:default] && !options[:default].new_record?
      default = options[:default]
      default_id = options[:default].try(:id)
    else
      default = resource.send(source)
      default_id = default.try(:id)
    end

    resource = resource.class.name.downcase
    source_path = Rails.application.routes.url_helpers.send("search_#{source}s_path", format: :json)
    %(
      <input id="#{source}" class="auto-suggest #{options[:class]}"
        type="text" value="#{default}" data-source-url="#{source_path}",
        placeholder="e.g. lettuce">
      <noscript class="text-warning">
        Warning: Javascript must be available to search and match crops
      </noscript>
      <input id="#{resource}_#{source}_id" class="auto-suggest-id"
        type="hidden" name="#{resource}[#{source}_id]" value="#{default_id}">
    ).html_safe
  end
end
