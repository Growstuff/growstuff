# frozen_string_literal: true

# The gardeners around a member: the ones they follow, people they might like
# to follow, and the ones nearby, and what they have all been doing lately.
# Nearby widens in rings, close by first and then further out, until there are
# enough people to show.
class Neighbours
  include SeasonsHelper

  SCOPES = %w(auto following nearby anywhere me).freeze
  # Scopes that look at one set of people, so no nearby ones and no suggestions.
  NARROW_SCOPES = %w(following me).freeze
  RADII_KM = [25, 150].freeze
  WORLD_KM = 20_000
  MIN_NEARBY = 3
  FEW_FOLLOWED = 3
  NEARBY_LIMIT = 100
  SUGGESTIONS_SHOWN = 4
  POSTS_SHOWN = 5
  FEED_KINDS = %i(planting harvest seed photo garden_layout transplant planned_job job_finished planting_finished seed_finished).freeze
  FEED_EVENTS = 15
  MAX_OFFSET = 500
  PHOTO_SUBJECTS = %w(Planting Harvest Seed Garden Job).freeze
  EVENT_MODELS = { 'planting' => Planting, 'harvest' => Harvest, 'seed' => Seed, 'photo' => Photo, 'garden_layout' => Garden,
                  'transplant' => PlantingHistory, 'job' => Job, 'job_finished' => Job, 'planting_finished' => Planting,
                  'seed_finished' => Seed }.freeze
  FEED_CACHE_FOR = 5.minutes

  # One band of distance: :near, :region or :anywhere. A ring that was
  # searched and held nobody is told apart from one never reached.
  Ring = Struct.new(:key, :people, :searched, keyword_init: true)
  # Why someone is suggested: crops in common, or the people they follow who
  # also follow them.
  Suggestion = Struct.new(:member, :crops, :followed_by, keyword_init: true)
  # One person's day: what they did, newest first, with how they are connected.
  # A photo item is about what it shows: its subject, a planting, harvest, seed
  # or garden.
  Item = Struct.new(:type, :record, :at, :subject, keyword_init: true)
  Entry = Struct.new(:owner, :day, :tag, :items, keyword_init: true) do
    def photos
      items.select { |item| item.type == 'photo' }
    end

    def others
      items.reject { |item| item.type == 'photo' }
    end

    # Photos of the same thing, together: [subject, how many]. A photo with
    # nothing to say what it shows is its own group.
    def photo_groups
      photos.group_by { |item| item.subject || item.record }.map { |subject, group| [subject, group.size, group.first.subject.nil?] }
    end
  end
  Day = Struct.new(:day, :updates, keyword_init: true)

  attr_reader :member, :scope, :offset

  def initialize(member, scope: nil, offset: 0)
    @member = member
    @scope = SCOPES.include?(scope) ? scope : 'auto'
    @offset = offset.to_i.clamp(0, MAX_OFFSET)
  end

  def shows_following?
    %w(auto following).include?(scope)
  end

  def shows_suggestions?
    scope == 'auto'
  end

  def shows_nearby?
    NARROW_SCOPES.exclude?(scope)
  end

  def located?
    member.latitude.present? && member.longitude.present?
  end

  # The first part of where they live, as they wrote it: "Wellington" for
  # "Wellington, NZ".
  def place
    member.location.to_s.split(',').first.to_s.strip.presence
  end

  def followed
    @followed ||= member.followed.confirmed.to_a
  end

  def few_followed?
    followed.size.between?(1, FEW_FOLLOWED - 1)
  end

  def suggestions
    @suggestions ||= shows_suggestions? ? hydrate_suggestions(cached('suggestions', 1.hour) { suggest_members }) : []
  end

  def rings
    @rings ||= shows_nearby? && located? ? hydrate_rings(cached('rings', 6.hours) { build_rings }) : []
  end

  # Whether nearby had to look beyond the first ring to find enough people.
  def widened?
    rings.many?(&:searched)
  end

  # Whether there was nobody in the first ring, so everyone shown is further out.
  def nobody_close?
    widened? && rings.first.people.empty?
  end

  def nearby_members
    rings.flat_map(&:people)
  end

  # The furthest ring that turned up anyone: what "near you" has come to mean.
  def reach
    rings.select { |ring| ring.people.any? }.last&.key
  end

  # Who the page is about, for its headings: people they follow and people
  # near them, or only one, or nearby once it has widened to somewhere.
  def audience
    return scope.to_sym if NARROW_SCOPES.include?(scope)
    return (widened? ? :all : :following_and_near) if followed.any? && shows_following?

    reach || :near
  end

  # What to say under the title: what they follow and how nearby went.
  def lede
    return :me if scope == 'me'

    if followed.empty? then nobody_close? ? :widened : :none
    elsif few_followed? then :few
    else :following
    end
  end

  def posts
    ids = cached('posts', 10.minutes) { Post.where(author_id: feed_owner_ids).recently_active.limit(POSTS_SHOWN).map(&:id) }
    @posts ||= Post.where(id: ids).preload(:author).index_by(&:id).values_at(*ids).compact
  end

  # Days of what people have lately planted, harvested, saved seeds of,
  # photographed, moved to another garden, planned jobs for, finished growing or
  # with, and rearranged their beds, newest first. One small chunk at a time,
  # from #offset.
  def feed
    build_feed unless defined?(@feed)
    @feed
  end

  # The hemispheres the feed spans, their own first, so each season marker can
  # name the season in each. Empty when nobody in it has said where they live.
  def hemispheres
    @hemispheres ||= begin
      latitudes = Member.where(id: feed_owner_ids).where.not(latitude: nil).distinct.pluck(Arel.sql('latitude < 0'))
      theirs = latitudes.map { |south| south ? :southern : :northern }
      ([hemisphere(member.latitude)] + theirs).compact.uniq
    end
  end

  def more_feed?
    build_feed unless defined?(@feed)
    @more_feed
  end

  def next_offset
    offset + FEED_EVENTS
  end

  # Names a cached piece of the page for this member. It changes with who they
  # follow, block and have dismissed, and where they live, so those take
  # effect at once; the rest waits for the entry to expire.
  def cache_key(*parts)
    ['neighbours', member.id, scope, member.latitude, member.longitude,
     Digest::SHA1.hexdigest([followed_ids, blocked_ids, dismissed_ids].map { |ids| ids.sort.join(',') }.join('|')), *parts]
  end

  private

  def cached(name, expires_in, &)
    Rails.cache.fetch(cache_key(name), expires_in:, &)
  end

  def followed_ids
    @followed_ids ||= member.follows.pluck(:followed_id)
  end

  def blocked_ids
    @blocked_ids ||= member.blocks.pluck(:blocked_id)
  end

  def dismissed_ids
    @dismissed_ids ||= member.member_dismissals.pluck(:dismissed_id)
  end

  def left_out_ids
    [member.id] + followed_ids + blocked_ids
  end

  def feed_owner_ids
    return [member.id] if scope == 'me'

    @feed_owner_ids ||= (shows_following? ? followed_ids : []) + nearby_members.map(&:id)
  end

  def within(radius)
    Member.confirmed.located.where.not(id: left_out_ids).near([member.latitude, member.longitude], radius, units: :km)
  end

  # Rings as plain data, so they can be cached: who is in each, as ids.
  def build_rings
    radii = scope == 'anywhere' ? [WORLD_KM] : RADII_KM + [WORLD_KM]
    keys = scope == 'anywhere' ? %i(anywhere) : %i(near region anywhere)
    found = 0
    inner_ids = []
    radii.zip(keys).map do |radius, key|
      next { key:, ids: [], searched: false } if found >= MIN_NEARBY && scope != 'anywhere'

      ids = within(radius).where.not(id: inner_ids).limit(NEARBY_LIMIT).map(&:id)
      found += ids.size
      inner_ids = within(radius).reorder(nil).pluck(:id) unless radius == WORLD_KM
      { key:, ids:, searched: true }
    end
  end

  def hydrate_rings(rings)
    people = Member.where(id: rings.flat_map { |ring| ring[:ids] }).index_by(&:id)
    rings.map do |ring|
      Ring.new(key: ring[:key], searched: ring[:searched], people: people.values_at(*ring[:ids]).compact)
    end
  end

  # People growing what they are, most in common first, then whoever was
  # planting most recently; then people their friends follow. As ids and names,
  # so they can be cached.
  def suggest_members
    (shared_crops + followed_by_friends).uniq { |suggestion| suggestion[:id] }.first(SUGGESTIONS_SHOWN)
  end

  def shared_crops
    mine = member.plantings.current.distinct.pluck(:crop_id)
    return [] if mine.empty?

    Planting.current.joins(:crop).where(crop_id: mine).where.not(owner_id: left_out_ids + dismissed_ids)
      .group(:owner_id)
      .order(Arel.sql('COUNT(DISTINCT plantings.crop_id) DESC'), Arel.sql('MAX(plantings.planted_at) DESC'))
      .limit(SUGGESTIONS_SHOWN)
      .pluck(:owner_id, Arel.sql('ARRAY_AGG(DISTINCT crops.name)'))
      .map { |id, crops| { id:, crops: crops.first(2), followed_by: [] } }
  end

  def followed_by_friends
    return [] if followed_ids.empty?

    Follow.where(follower_id: followed_ids).where.not(followed_id: left_out_ids + dismissed_ids)
      .group(:followed_id).order(Arel.sql('COUNT(*) DESC')).limit(SUGGESTIONS_SHOWN)
      .pluck(:followed_id, Arel.sql('ARRAY_AGG(follower_id)'))
      .map { |id, follower_ids| { id:, crops: [], followed_by: follower_ids.first(2) } }
  end

  def hydrate_suggestions(suggestions)
    people = Member.confirmed.where(id: suggestions.flat_map { |suggestion| [suggestion[:id], *suggestion[:followed_by]] }).index_by(&:id)
    suggestions.filter_map do |suggestion|
      next unless people[suggestion[:id]]

      Suggestion.new(member: people[suggestion[:id]], crops: suggestion[:crops],
                     followed_by: people.values_at(*suggestion[:followed_by]).compact)
    end
  end

  def build_feed
    rows = feed_rows
    @more_feed = rows.size > FEED_EVENTS
    @feed = days_of(rows.first(FEED_EVENTS))
  end

  def feed_rows
    return [] if feed_owner_ids.empty?

    TimelineService.query(FEED_KINDS).where(owner_id: feed_owner_ids).offset(offset).limit(FEED_EVENTS + 1).to_a
  end

  def days_of(rows)
    records = load_records(rows)
    owners = Member.where(id: rows.map(&:owner_id)).index_by(&:id)
    entries = rows.group_by { |row| [day_of(row.event_at), row.owner_id] }.map do |(day, owner_id), group|
      items = group.filter_map { |row| item_for(row, records) }
      Entry.new(owner: owners[owner_id], day:, tag: tag_for(owner_id), items:) if owners[owner_id] && items.any?
    end
    entries.compact.group_by(&:day).map { |day, updates| Day.new(day:, updates:) }
  end

  def load_records(rows)
    records = rows.group_by(&:event_type).to_h do |type, group|
      scope = EVENT_MODELS.fetch(type).where(id: group.map(&:id))
      scope = scope.includes(:crop) if %w(planting harvest seed planting_finished seed_finished).include?(type)
      scope = scope.includes(:garden, planting: [:crop, :garden, { histories: :garden }]) if type == 'transplant'
      [type, scope.index_by(&:id)]
    end
    records['photo_subjects'] = photo_subjects(records.fetch('photo', {}).keys)
    records
  end

  # What each photo is of: the first of a planting, harvest, seed or garden it
  # is attached to.
  def photo_subjects(photo_ids)
    return {} if photo_ids.empty?

    links = PhotoAssociation.where(photo_id: photo_ids, photographable_type: PHOTO_SUBJECTS).pluck(:photo_id, :photographable_type,
                                                                                                   :photographable_id)
    subjects = links.group_by { |_photo_id, type, _id| type }.to_h do |type, group|
      model = type.constantize
      model = model.includes(:crop) unless %w(Garden Job).include?(type)
      [type, model.where(id: group.map(&:last)).index_by(&:id)]
    end
    links.sort_by { |_photo_id, type, _id| PHOTO_SUBJECTS.index(type) }.each_with_object({}) do |(photo_id, type, id), found|
      found[photo_id] ||= subjects[type][id]
    end
  end

  def item_for(row, records)
    record = records.dig(row.event_type, row.id)
    return unless record

    at = row.event_at.in_time_zone unless midnight?(row.event_at)
    Item.new(type: row.event_type, record:, at:, subject: records['photo_subjects'][row.id])
  end

  # Dates come through the timeline as midnight, in whatever zone the database
  # connection reads times in, so they have no time of day.
  def midnight?(time)
    !time.respond_to?(:hour) || time.seconds_since_midnight.zero?
  end

  def day_of(time)
    return time.to_date unless time.respond_to?(:hour)

    midnight?(time) ? time.to_date : time.in_time_zone.to_date
  end

  def tag_for(owner_id)
    return :following if followed_ids.include?(owner_id)

    :near if rings.first&.people&.any? { |person| person.id == owner_id }
  end
end
