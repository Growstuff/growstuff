class SeedSweeper < ActionController::Caching::Sweeper
  observe Seed

  def after_destroy(seed)
    if seed.tradable? && seed.interesting?
      Rails.cache.delete('interesting_seeds')
    end
  end

end


