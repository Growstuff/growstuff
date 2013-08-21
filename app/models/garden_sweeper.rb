class GardenSweeper < ActionController::Caching::Sweeper
  observe Garden

  def after_create(garden)
    expire_fragment('homepage_stats')
  end

  def after_destroy(garden)
    expire_fragment('homepage_stats')
  end
end

