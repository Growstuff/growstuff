# frozen_string_literal: true

class TimelineService
  def self.member_query(member)
    query.where(owner_id: member.id)
  end

  # A timeline of events by people the member follows
  def self.followed_query(member)
    query.where(owner_id: [member.followed.pluck(:id)])
  end

  def self.query
    plantings_query
      .union_all(harvests_query)
      .union_all(posts_query)
      .union_all(comments_query)
      .union_all(photos_query)
      .union_all(seeds_query)
      .where.not(event_at: nil)
      .order(event_at: :desc)
  end

  def self.plantings_query
    Planting.select(
      :id,
      "'planting' as event_type",
      'planted_at as event_at',
      :owner_id,
      :crop_id
    )
  end

  def self.harvests_query
    Harvest.select(
      :id,
      "'harvest' as event_type",
      'harvested_at as event_at',
      :owner_id,
      :crop_id
    )
  end

  def self.seeds_query
    Seed.select(
      :id,
      "'seed' as event_type",
      "seeds.created_at as event_at",
      :owner_id,
      :crop_id
    )
  end

  def self.posts_query
    Post.select(
      :id,
      "'post' as event_type",
      'posts.created_at as event_at',
      'author_id as owner_id',
      'null as crop_id'
    )
  end

  def self.comments_query
    Comment.select(
      :id,
      "'comment' as event_type",
      'comments.created_at as event_at',
      'author_id as owner_id',
      'null as crop_id'
    )
  end

  def self.photos_query
    Photo.select(
      :id,
      "'photo' as event_type",
      "photos.created_at as event_at",
      :owner_id,
      'null as crop_id'
    )
  end
end
