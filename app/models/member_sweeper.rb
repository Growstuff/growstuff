class MemberSweeper < ActionController::Caching::Sweeper
  observe Member

  def after_create(member)
    expire_fragment('homepage_stats')
  end

  def after_update(member)
    expire_fragment("member_thumbnail_#{member.slug}")
  end

end

