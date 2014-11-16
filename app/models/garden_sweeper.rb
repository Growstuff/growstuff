class GardenSweeper < Sweeper
  observe Garden

  def after_create(garden)
    expire_fragment('homepage_stats')
    expire_fragment('interesting_members') if garden.owner.interesting?
    expire_fragment("member_thumbnail_#{garden.owner.id}")
  end

  def after_destroy(garden)
    expire_fragment('homepage_stats')
    expire_fragment('interesting_members') if garden.owner.interesting?
    expire_fragment("member_thumbnail_#{garden.owner.id}")
  end
end

