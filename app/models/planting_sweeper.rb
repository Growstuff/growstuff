class PlantingSweeper < ActionController::Caching::Sweeper
  observe Planting

  def after_create(planting)
    expire_cache_for(planting)
  end

  def after_update(planting)
    expire_cache_for(planting)
  end

  def after_destroy(planting)
    expire_cache_for(planting)
  end

  private
  def expire_cache_for(planting)
    expire_fragment('recent_plantings')
  end
end

