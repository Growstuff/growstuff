# frozen_string_literal: true

class TimelineService
  def self.member_query(member)
    query.where(owner_id: member.id)
  end

  # A timeline of events by people the member follows
  def self.followed_query(member)
    query.where(owner_id: [member.followed.pluck(:id)])
  end

  # What the timeline is made of, and the query for each kind of event.
  EVENT_QUERIES = {
    planting:          :plantings_query,
    harvest:           :harvests_query,
    post:              :posts_query,
    comment:           :comments_query,
    photo:             :photos_query,
    seed:              :seeds_query,
    activity:          :activities_query,
    like:              :likes_query,
    garden_layout:     :garden_layouts_query,
    transplant:        :transplants_query,
    planting_finished: :plantings_finished_query,
    seed_finished:     :seeds_finished_query
  }.freeze
  DEFAULT_EVENTS = %i(planting harvest post comment photo seed activity like).freeze

  # Events of the given kinds, newest first. Garden layouts are only here when
  # asked for, since the timeline page has nothing to say about them; the same goes
  # for transplants and finished plantings and seeds.
  def self.query(kinds = DEFAULT_EVENTS)
    kinds.map { |kind| public_send(EVENT_QUERIES.fetch(kind)) }
      .reduce { |all, one| all.union_all(one) }
      .where.not(event_at: nil)
      .order(event_at: :desc)
  end

  def self.garden_layouts_query
    Garden.where.not(layout_saved_at: nil)
      .select(:id, "'garden_layout' as event_type", 'gardens.layout_saved_at as event_at', :owner_id, 'null as crop_id')
  end

  def self.plantings_finished_query
    Planting.where(failed: [false, nil])
      .where('plantings.finished_at <= ? OR (plantings.finished_at IS NULL AND plantings.finished = ?)', Time.zone.today, true)
      .select(:id, "'planting_finished' as event_type", 'COALESCE(plantings.finished_at, plantings.updated_at) as event_at',
              :owner_id, :crop_id)
  end

  def self.seeds_finished_query
    Seed.where(finished_at: ..Time.zone.today)
      .select(:id, "'seed_finished' as event_type", 'seeds.finished_at as event_at', :owner_id, :crop_id)
  end

  def self.transplants_query
    PlantingHistory.joins(:planting)
      .select('planting_histories.id', "'transplant' as event_type", 'planting_histories.ended_on as event_at',
              'plantings.owner_id', 'plantings.crop_id')
  end

  def self.likes_query
    Like
      .select("likes.id",
              "'like' as event_type",
              "likes.created_at as event_at",
              "likes.member_id as owner_id",
              "null as crop_id")
  end

  def self.activities_query
    Activity.select(
      :id,
      "'activity' as event_type",
      'COALESCE(activities.due_date, activities.created_at) as event_at',
      :owner_id,
      'null as crop_id'
    )
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
