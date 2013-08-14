class PlantingSweeper < ActionController::Caching::Sweeper
  observe Planting

  def after_create(planting)
    expire_fragment('homepage_stats')
    expire_fragment("member_thumbnail_#{planting.owner.slug}")
    expire_fragment("crop_image_#{planting.crop.id}")
  end

  def after_update(planting)
    expire_fragment("planting_listitem_#{planting.id}")
  end

  def after_destroy(planting)
    expire_fragment('homepage_stats')
    expire_fragment("crop_image_#{planting.crop.id}")
    Rails.cache.delete('interesting_plantings') if planting.interesting?
  end

end

