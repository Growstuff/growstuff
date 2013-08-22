class SeedSweeper < ActionController::Caching::Sweeper
  observe Seed

  def after_create(seed)
    if seed.tradable? && seed.interesting?
      expire_fragment('interesting_seeds')
    end
    expire_fragment('interesting_members') if seed.owner.interesting?
    expire_fragment("member_thumbnail_#{seed.owner.id}")
  end

  def after_update(seed)
    expire_fragment('interesting_seeds')
  end

  def after_destroy(seed)
    if seed.tradable? && seed.interesting?
      expire_fragment('interesting_seeds')
    end
    expire_fragment('interesting_members') if seed.owner.interesting?
    expire_fragment("member_thumbnail_#{seed.owner.id}")
  end

end


