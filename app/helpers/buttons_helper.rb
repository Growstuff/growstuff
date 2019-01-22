module ButtonsHelper
  def garden_plant_something_button(garden)
    button(new_planting_path(garden_id: garden.id), 'buttons.plant_something_here', 'leaf')
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
    return unless can?(:edit, planting)

    button(
      planting_path(planting, planting: { finished: 1 }),
      'buttons.mark_as_finished',
      'ok'
    )
  end

  def planting_harvest_button(planting)
    return unless planting.active? && can?(:create, Harvest) && can?(:edit, planting)

    button(new_planting_harvest_path(planting), 'buttons.harvest', 'apple')
  end

  def planting_save_seeds_button(planting)
    button(new_planting_seed_path(planting), 'buttons.save_seeds', 'heart') if can?(:edit, planting)
  end

  # Generic buttons (works out which model)
  def add_photo_button(model)
    return unless can?(:edit, model) && can?(:create, Photo)

    button(
      new_photo_path(id: model.id, type: model_type_for_photo(model)),
      'buttons.add_a_photo', 'camera')
  end


  def edit_button(path)
    button(path, 'buttons.edit', 'pencil')
  end

  def delete_button(model, message: 'are_you_sure')
    return unless can? :destroy, model
    link_to model, method: :delete, data: { confirm: t(message) }, class: 'btn btn-default btn-xs' do
      render 'shared/glyphicon', icon: 'trash', title: 'buttons.delete'
    end
  end

  private

  def model_type_for_photo(model)
    ActiveModel::Name.new(model.class).to_s.downcase
  end

  def button(path, title, icon, size = 'btn-xs')
    link_to path, class: "btn btn-default #{size}" do
      render 'shared/glyphicon', icon: icon, title: title
    end
  end
end
