class PlantingSweeper < Sweeper
  observe Planting

  def after_create(planting)
    expire_fragment('homepage_stats')
    expire_fragment("member_thumbnail_#{planting.owner.id}")
    expire_fragment("interesting_members") if planting.owner.interesting?
    expire_fragment("crop_image_#{planting.crop.id}")
  end

  def after_update(planting)
    expire_fragment("planting_listitem_#{planting.id}")
    expire_fragment("planting_image_#{planting.id}")
    expire_fragment("interesting_plantings")
  end

  def after_destroy(planting)
    expire_fragment('homepage_stats')
    expire_fragment("crop_image_#{planting.crop.id}")
    expire_fragment('interesting_plantings') if planting.interesting?
    expire_fragment("interesting_members") if planting.owner.interesting?
  end

end

