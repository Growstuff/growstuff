class MemberSweeper < ActionController::Caching::Sweeper
  observe Member

  def after_create(member)
    expire_fragment('homepage_stats')
  end

  def after_update(member)
    expire_fragment('interesting_members') if member.interesting?
    expire_fragment("interesting_seeds") if member.seeds.tradable.present?
    expire_fragment("member_thumbnail_#{member.id}")

    if member.plantings.present?
      member.plantings.each do |p|
        expire_fragment("plantings_listitem_#{p.id}") if p.interesting?
      end
      expire_fragment('interesting_plantings')
    end

  end

end

