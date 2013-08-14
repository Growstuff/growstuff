class PlantingSweeper < ActionController::Caching::Sweeper
  observe Planting

  def after_create(planting)
    expire_fragment('homepage_stats')
    expire_fragment("member_thumbnail_#{planting.owner.slug}")
  end

  def after_destroy(planting)
    expire_fragment('homepage_stats')
  end

end

