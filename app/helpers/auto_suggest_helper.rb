module AutoSuggestHelper

  def auto_suggest(resource, source)
    default = resource.send(source).nil? ? "" : resource.send(source).name

    resource = resource.class.name.downcase
    source_path = Rails.application.routes.url_helpers.send("#{source}s_search_path")

    %Q{
      <input id="#{source}" class="auto-suggest" type="text" value="#{default}" data-source-url="#{source_path}">
      <input id="#{resource}_#{source}_id" class="auto-suggest-id" type="hidden" name="#{resource}[#{source}_id]">
    }.html_safe
  end

end