module AutoSuggestHelper

  def auto_suggest(resource, source, options={})
    default = resource.send(source)
    default_name = default.name || ""
    default_id = default.id || ""

    resource = resource.class.name.downcase
    source_path = Rails.application.routes.url_helpers.send("#{source}s_search_path")

    %Q{
      <input id="#{source}" class="auto-suggest #{options[:class]}" type="text" value="#{default_name}" data-source-url="#{source_path}">
      <noscript class="text-warning">Warning: Javascript must be available to search and match crops</noscript>
      <input id="#{resource}_#{source}_id" class="auto-suggest-id" type="hidden" name="#{resource}[#{source}_id]" value="#{default_id}">
    }.html_safe
  end

end