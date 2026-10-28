# frozen_string_literal: true

module ButtonsHelper
  include IconsHelper
  include PhotosHelper

  def garden_plan_something_button(garden, classes: "btn btn-outline-secondary")
    return unless can? :edit, garden

    link_to new_job_path(garden_id: garden.id), class: classes do
      job_icon + ' ' + t('buttons.new_job')
    end
  end

  def garden_mark_active_button(garden, classes: 'btn')
    link_to t('buttons.mark_as_active'),
            garden_path(garden, garden: { active: 1 }),
            method: :put, class: classes
  end

  def add_photo_button(model, classes: "btn btn-outline-secondary")
    return unless can?(:edit, model) && can?(:create, Photo)

    link_to new_photo_path_for(model), class: classes, data: photo_dialog_data(model) do
      add_photo_icon + ' ' + t('buttons.add_photo')
    end
  end

  def delete_button(model, message: 'are_you_sure', classes: 'btn btn-danger', icon: delete_icon)
    return unless can? :destroy, model

    link_to model, method: :delete, data: { confirm: t(message) }, class: classes do
      icon + ' ' + t('buttons.delete')
    end
  end

  # The page (or dialog) for adding a photo of this record.
  def new_photo_path_for(model)
    new_photo_path(id: model.id, type: ActiveModel::Name.new(model.class).to_s.downcase)
  end
end
