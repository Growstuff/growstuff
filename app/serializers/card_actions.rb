# frozen_string_literal: true

# What the serializers for the React cards share: the menu items (each a label and
# a link, with `method` and `confirm` for non-GET links), and who may see them.
module CardActions
  private

  def routes
    Rails.application.routes.url_helpers
  end

  def can?(*)
    @ability.can?(*)
  end

  # options: method (for non-GET links, as jquery_ujs data-method), confirm, divider.
  def action(key, label, href, **options)
    { key: key, label: label, href: href, **options }.compact
  end

  def photo_action(model)
    return unless can?(:edit, model) && can?(:create, Photo)

    type = ActiveModel::Name.new(model.class).to_s.downcase
    action(:photo, I18n.t('buttons.add_photo'), routes.new_photo_path(id: model.id, type: type))
  end
end
