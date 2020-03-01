# frozen_string_literal: true

module ButtonsHelper
  include IconsHelper
  def garden_plant_something_button(garden, classes: "btn btn-default")
    return unless can? :edit, garden

    link_to new_planting_path(garden_id: garden.id), class: classes do
      planting_icon + ' ' + t('buttons.plant_something_here')
    end
  end

  def plant_something_button
    return unless can? :create, Planting

    link_to new_planting_path, class: "btn btn-default" do
      planting_icon + ' ' + t('buttons.plant_something')
    end
  end

  def garden_mark_active_button(garden, classes: 'btn')
    link_to t('buttons.mark_as_active'),
            garden_path(garden, garden: { active: 1 }),
            method: :put, class: classes
  end

  def garden_mark_inactive_button(garden, classes: 'btn')
    link_to t('buttons.mark_as_inactive'),
            garden_path(garden, garden: { active: 0 }),
            method: :put, class: classes,
            data: { confirm: 'All plantings associated with this garden will be marked as finished. Are you sure?' }
  end

  def create_button(model_to_create, path, icon, label)
    return unless can?(:create, model_to_create)

    link_to path, class: "btn btn-sm" do
      icon + ' ' + label
    end
  end

  def crop_edit_button(crop)
    edit_button(edit_crop_path(crop))
  end

  def seed_edit_button(seed, classes: "btn btn-raised btn-info")
    edit_button(edit_seed_path(seed), classes: classes)
  end

  def harvest_edit_button(harvest, classes: "btn btn-raised btn-info")
    edit_button(edit_harvest_path(harvest), classes: classes)
  end

  def garden_edit_button(garden, classes: "btn btn-raised btn-info")
    edit_button(edit_garden_path(garden), classes: classes)
  end

  def planting_edit_button(planting, classes: "btn btn-raised btn-info")
    edit_button(edit_planting_path(planting), classes: classes)
  end

  def planting_finish_button(planting, classes: 'btn btn-default btn-secondary')
    return unless can?(:edit, planting) || planting.finished

    link_to planting_path(slug: planting.slug, planting: { finished: 1 }),
            method: :put, class: "#{classes} append-date" do
      finished_icon + ' ' + t('buttons.mark_as_finished')
    end
  end

  def seed_finish_button(seed, classes: 'btn btn-default')
    return unless can?(:create, Planting) && seed.active

    link_to seed_path(seed, seed: { finished: 1 }), method: :put, class: "#{classes} append-date" do
      finished_icon + ' ' + t('buttons.mark_as_finished')
    end
  end

  def planting_harvest_button(planting, classes: 'btn btn-default')
    return unless planting.active && can?(:create, Harvest) && can?(:edit, planting)

    link_to new_planting_harvest_path(planting_slug: planting.slug), class: classes do
      harvest_icon + ' ' + t('buttons.record_harvest')
    end
  end

  def planting_save_seeds_button(planting, classes: 'btn btn-default')
    return unless can?(:edit, planting)

    link_to new_planting_seed_path(planting_slug: planting.slug), class: classes do
      seed_icon + ' ' + t('buttons.save_seeds')
    end
  end

  def add_photo_button(model, classes: "btn btn-default")
    return unless can?(:edit, model) && can?(:create, Photo)

    link_to new_photo_path(id: model.id, type: model_type_for_photo(model)),
            class: classes do
      add_photo_icon + ' ' + t('buttons.add_photo')
    end
  end

  def edit_button(path, classes: "btn btn-raised btn-info")
    link_to path, class: classes do
      edit_icon + ' ' + t('buttons.edit')
    end
  end

  def delete_button(model, message: 'are_you_sure', classes: 'btn btn-danger')
    return unless can? :destroy, model

    link_to model, method: :delete, data: { confirm: t(message) }, class: classes do
      delete_icon + ' ' + t('buttons.delete')
    end
  end

  private

  def model_type_for_photo(model)
    ActiveModel::Name.new(model.class).to_s.downcase
  end

  def button(path, button_title, icon, size = 'btn-xs')
    link_to path, class: "btn btn-default #{size}" do
      icon + ' ' + button_title
    end
  end
end
