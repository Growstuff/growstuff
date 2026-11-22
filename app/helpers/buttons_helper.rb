# frozen_string_literal: true

module ButtonsHelper
  include IconsHelper
  include PhotosHelper

  def garden_mark_active_button(garden, classes: 'btn')
    link_to t('buttons.mark_as_active'),
            garden_path(garden, garden: { active: 1 }),
            method: :put, class: classes
  end

  def delete_button(model, message: 'are_you_sure', classes: 'btn btn-danger', icon: delete_icon)
    return unless can? :destroy, model

    link_to model, method: :delete, data: { confirm: t(message) }, class: classes do
      icon + ' ' + t('buttons.delete')
    end
  end

  # The page (or dialog) for adding a photo of this record.
  # `params` go on the link too, such as the `label` of a seed packet photo.
  def new_photo_path_for(model, **params)
    new_photo_path(id: model.id, type: ActiveModel::Name.new(model.class).to_s.downcase, **params)
  end
end
