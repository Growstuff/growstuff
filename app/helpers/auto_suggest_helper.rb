module AutoSuggestHelper

  def auto_suggest(resource, source, options={})
    default = resource.send(source).nil? ? "" : resource.send(source).name

    resource = resource.class.name.downcase
    source_path = Rails.application.routes.url_helpers.send("#{source}s_search_path")

    %Q{
      <input id="#{source}" class="auto-suggest #{options[:class]}" type="text" value="#{default}" data-source-url="#{source_path}">
      <noscript class="text-warning">Warning: Javascript must be available to search and match crops</noscript>
      <input id="#{resource}_#{source}_id" class="auto-suggest-id" type="hidden" name="#{resource}[#{source}_id]">
    }.html_safe
  end

end