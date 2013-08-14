class MemberSweeper < ActionController::Caching::Sweeper
  observe Member

  def after_create(member)
    expire_fragment('homepage_stats')
  end

  def after_update(member)
    if member.location.blank?
      Rails.cache.delete('interesting_members')
    end
    expire_fragment("member_thumbnail_#{member.id}")
  end

end

