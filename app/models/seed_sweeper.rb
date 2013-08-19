class SeedSweeper < ActionController::Caching::Sweeper
  observe Seed

  def after_create(seed)
    if seed.tradable? && seed.interesting?
      expire_fragment('interesting_seeds')
    end
  end

  def after_update(seed)
    expire_fragment('interesting_seeds')
  end

  def after_destroy(seed)
    if seed.tradable? && seed.interesting?
      expire_fragment('interesting_seeds')
    end
  end

end


