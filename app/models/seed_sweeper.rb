class SeedSweeper < ActionController::Caching::Sweeper
  observe Seed

  def after_destroy(seed)
    if seed.tradable? && seed.interesting?
      expire_fragment('interesting_seeds')
    end
  end

end


