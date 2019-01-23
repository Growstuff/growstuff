module ButtonsHelper
  include IconsHelper
  def garden_plant_something_button(garden)
    link_to new_planting_path(garden_id: garden.id), class: "btn btn-default btn-xs btn-primary" do
      planting_icon + ' ' + t('buttons.plant_something_here')
    end
  end

  def garden_mark_active_button(garden)
    link_to t('buttons.mark_as_active'),
      garden_path(garden, garden: { active: 1 }),
      method: :put, class: 'btn btn-default btn-xs'
  end

  def garden_mark_inactive_button(garden)
    link_to t('buttons.mark_as_inactive'),
      garden_path(garden, garden: { active: 0 }),
      method: :put, class: 'btn btn-default btn-xs',
      data: { confirm: 'All plantings associated with this garden will be marked as finished. Are you sure?' }
  end

  def crop_edit_button(crop)
    edit_button(edit_crop_path(crop))
  end

  def seed_edit_button(seed)
    edit_button(edit_seed_path(seed))
  end

  def harvest_edit_button(harvest)
    edit_button(edit_harvest_path(harvest))
  end

  def garden_edit_button(garden)
    edit_button(edit_garden_path(garden))
  end

  def planting_edit_button(planting)
    edit_button(edit_planting_path(planting))
  end

  def planting_finish_button(planting)
    return unless can?(:edit, planting) || planting.finished

    link_to planting_path(planting, planting: { finished: 1 }),
      method: :put, class: 'btn btn-default btn-xs append-date' do
      finished_icon + ' ' + t('buttons.mark_as_finished')
    end
  end

  def planting_harvest_button(planting)
    return unless planting.active? && can?(:create, Harvest) && can?(:edit, planting)

    link_to new_planting_harvest_path(planting), class: "btn btn-default btn-xs" do
      harvest_icon + ' ' + t('buttons.harvest')
    end
  end

  def planting_save_seeds_button(planting)
    return unless can?(:edit, planting)

    link_to new_planting_seed_path(planting), class: "btn btn-default btn-xs" do
      seed_icon + ' ' + t('buttons.save_seeds')
    end
  end

  def add_photo_button(model)
    return unless can?(:edit, model) && can?(:create, Photo)

    link_to new_photo_path(id: model.id, type: model_type_for_photo(model)),
      class: "btn btn-default btn-xs" do
      photo_icon + ' ' + t('buttons.add_photo')
    end
  end

  def edit_button(path)
    link_to path, class: "btn btn-default btn-xs" do
      edit_icon + ' ' + t('buttons.edit')
    end
  end

  def delete_button(model, message: 'are_you_sure')
    return unless can? :destroy, model

    link_to model, method: :delete, data: { confirm: t(message) }, class: 'btn btn-default btn-xs' do
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
