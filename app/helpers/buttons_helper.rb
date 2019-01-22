module ButtonsHelper
  def seed_add_photo_button(seed)
    button(new_photo_path(id: seed.id, type: "seed"), 'buttons.add_a_photo', 'camera')
  end
  
  def harvest_add_photo_button(harvest)
    button(new_photo_path(id: harvest.id, type: "harvest"), 'buttons.add_a_photo', 'camera')
  end

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

  def garden_add_photo_button(garden)
    button(new_photo_path(id: garden.id, type: "garden"), 'buttons.add_a_photo', 'camera')
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

  def planting_add_photo_button(planting)
    button(new_photo_path(id: planting.id, type: 'planting'), 'buttons.add_photo', 'camera')
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

  def edit_button(path)
    button(path, 'buttons.edit', 'pencil')
  end

  def delete_button(model, message: 'are_you_sure')
    link_to model, method: :delete, data: { confirm: t(message) }, class: 'btn btn-default btn-xs' do
      render 'shared/glyphicon', icon: 'trash', title: 'buttons.delete'
    end
  end

  private

  def button(path, title, icon, size = 'btn-xs')
    link_to path, class: "btn btn-default #{size}" do
      render 'shared/glyphicon', icon: icon, title: title
    end
  end
end
