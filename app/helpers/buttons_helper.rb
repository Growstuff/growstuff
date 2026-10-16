# frozen_string_literal: true

module ButtonsHelper
  include IconsHelper

  def garden_plant_something_button(garden, classes: "btn btn-outline-secondary")
    return unless can? :edit, garden

    link_to new_planting_path(garden_id: garden.id), class: classes do
      planting_icon + ' ' + t('buttons.plant_something_here')
    end
  end

  def garden_plan_something_button(garden, classes: "btn btn-outline-secondary")
    return unless can? :edit, garden

    link_to new_activity_path(garden_id: garden.id), class: classes do
      activity_icon + ' ' + t('buttons.new_activity')
    end
  end

  def garden_mark_active_button(garden, classes: 'btn')
    link_to t('buttons.mark_as_active'),
            garden_path(garden, garden: { active: 1 }),
            method: :put, class: classes
  end

  def add_photo_button(model, classes: "btn btn-outline-secondary")
    return unless can?(:edit, model) && can?(:create, Photo)

    link_to new_photo_path(id: model.id, type: model_type_for_photo(model)),
            class: classes, data: photo_dialog_data(model) do
      add_photo_icon + ' ' + t('buttons.add_photo')
    end
  end

  def edit_button(path, classes: "btn btn-raised btn-info")
    link_to path, class: classes do
      edit_icon + ' ' + t('buttons.edit')
    end
  end

  def delete_button(model, message: 'are_you_sure', classes: 'btn btn-danger', icon: delete_icon)
    return unless can? :destroy, model

    link_to model, method: :delete, data: { confirm: t(message) }, class: classes do
      icon + ' ' + t('buttons.delete')
    end
  end

  def model_type_for_photo(model)
    ActiveModel::Name.new(model.class).to_s.downcase
  end

  def button(path, button_title, icon, size = 'btn-sm')
    link_to path, class: "btn btn-outline-secondary #{size}" do
      icon + ' ' + button_title
    end
  end
end
