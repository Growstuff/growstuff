# frozen_string_literal: true

class Crop < ApplicationRecord
  has_paper_trail
  extend FriendlyId
  include PhotoCapable
  include OpenFarmData
  include GbifData
  include SearchCrops
  include Jobbable

  friendly_id :name, use: %i(slugged finders)

  # The ranges a crop wrangler sets and members' seed packets give, which the crop keeps the median of.
  HARDINESS_SOURCES = %w(seed_packets manual).freeze
  PACKET_RANGES = %i(germination_days_min germination_days_max days_until_maturity_min days_until_maturity_max).freeze

  ##
  ## Relationships
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_crops
  belongs_to :requester, class_name: 'Member', optional: true, inverse_of: :requested_crops
  belongs_to :parent, class_name: 'Crop', optional: true, inverse_of: :varieties
  has_many :scientific_names, as: :subject, dependent: :delete_all
  has_many :alternate_names, as: :subject, dependent: :delete_all
  has_many :plantings, dependent: :destroy
  has_many :seeds, dependent: :destroy
  has_many :harvests, dependent: :destroy
  has_many :photo_associations, dependent: :delete_all, inverse_of: :crop
  has_many :photos, -> { where.not(id: PhotoAssociation.of_packets.select(:photo_id)) }, through: :photo_associations
  has_many :plant_parts, -> { joins_members.distinct.order("plant_parts.name") }, through: :harvests
  has_many :varieties, class_name: 'Crop', foreign_key: 'parent_id', dependent: :nullify, inverse_of: :parent
  has_many :crop_companions, foreign_key: :crop_a_id, dependent: :delete_all, inverse_of: :crop_a
  has_many :companions, through: :crop_companions, source: :crop_b, class_name: 'Crop'
  has_many :crop_job_templates, dependent: :destroy
  has_many :crop_posts, dependent: :delete_all
  has_many :posts, through: :crop_posts, dependent: :delete_all
  has_one :australian_food_classification_data,
          foreign_key: :public_food_key,
          primary_key: :public_food_key,
          inverse_of:  :crop

  accepts_nested_attributes_for :scientific_names, allow_destroy: true, reject_if: :all_blank

  ##
  ## Scopes
  scope :recent, -> { approved.order(created_at: :desc) }
  scope :toplevel, -> { approved.where(parent_id: nil) }
  scope :popular, -> { approved.order(Arel.sql("plantings_count desc, lower(name) asc")) }
  scope :pending_approval, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }
  scope :interesting, -> { approved.has_photos }
  scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }
  scope :joins_members, -> { joins("INNER JOIN members ON members.id = harvests.owner_id") }

  # Whether a plant is harvested once ('single', like a lettuce) or keeps producing
  # ('repeated', like a tomato). Empty when we don't know.
  enum :harvest_style, { single: 'single', repeated: 'repeated' }, prefix: true, validate: { allow_nil: true }

  ##
  ## Validations
  # Reasons are only necessary when rejecting
  validates :reason_for_rejection, presence: true, if: :rejected?
  validate :must_be_rejected_if_rejected_reasons_present
  validate :must_have_meaningful_reason_for_rejection
  ## Wikipedia urls are only necessary when approving a crop
  validates :en_wikipedia_url,
            format: {
              with:    %r{\Ahttps?://en\.wikipedia\.org/wiki/[[:alnum:]%_.()-]+\z},
              message: :not_a_valid_wikipedia_url
            },
            if:     :approved?
  validates :en_youtube_url,
            format: {
              with:    %r{\A(?:https?://)?(?:www\.)?(?:youtube(?:-nocookie)?\.com/(?:(?:v|e(?:mbed)?)/|\S*?[?&]v=)|youtu\.be/)[a-zA-Z0-9_-]{11}(?:[?&]\S*)?\z},
              message: :not_a_valid_youtube_url
            },
            allow_blank: true
  validates :name, uniqueness: { scope: :approval_status }, if: :pending?
  validates :hardiness, inclusion: { in: Hardiness::VALUES }
  validates :hardiness_source, inclusion: { in: HARDINESS_SOURCES }, allow_nil: true
  validates(*PACKET_RANGES, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true)
  normalizes :sow_months, with: ->(months) { Array(months).compact_blank.map(&:to_i).uniq.sort }
  validate :sow_months_are_months
  validates :default_diameter, allow_nil: true, numericality: {
    greater_than: 0, less_than_or_equal_to: Plant::MAX_DIAMETER
  }
  validates :icon, allow_blank: true, inclusion: { in: ->(_) { icon_names } }

  # Crop icons that ship with the app: Microsoft's Fluent Emoji (MIT licensed;
  # see COPYRIGHT there), one per food plant or flower they draw.
  ICON_DIR = Rails.root.join('app/assets/images/crops')

  def self.icon_names
    @icon_names ||= Dir[ICON_DIR.join('*.svg')].map { |path| File.basename(path, '.svg') }.sort
  end

  # Read once and kept, as crop chips ask for these a lot.
  def self.icon_svg(name)
    @icon_svgs ||= {}
    @icon_svgs[name] ||= ICON_DIR.join("#{name}.svg").read
  end

  def to_s
    name
  end

  # How many grid cells across one of these plants is drawn on a bed's layout.
  # Falls back to the parent crop's, as the icon does, so a variety of tomato
  # follows tomato unless it has its own.
  def layout_diameter
    default_diameter || parent&.layout_diameter
  end

  # This crop's icon as SVG: the one chosen for it, else the one OpenFarm had,
  # else its parent crop's, so a variety of tomato gets the tomato. Nil when
  # none of those has one; crops#show then serves a sprout.
  def svg_icon
    return self.class.icon_svg(icon) if icon.present?

    openfarm_svg_icon.presence || parent&.svg_icon
  end

  def to_param
    slug
  end

  def default_scientific_name
    scientific_names.first
  end

  def ecocrop_data
    # Match against any of the crop's scientific names, starting with default
    scientific_names.each do |sn|
      record = EcocropData.by_scientific_name(sn.name)
      return record if record.present?
    end
    nil
  end

  # This crop's harvest style if it has one, else its parent's, so a variety of lettuce follows lettuce.
  def effective_harvest_style
    harvest_style || parent&.effective_harvest_style
  end

  # The EcoCrop record with the figures for a heat estimate: this crop's if it has them, else its parent's,
  # so a variety of tomato follows tomato.
  def ecocrop_heat_data
    return @ecocrop_heat_data if defined?(@ecocrop_heat_data)

    data = ecocrop_data
    @ecocrop_heat_data = data&.heat_data? ? data : parent&.ecocrop_heat_data
  end

  # What a crop wrangler has set by hand, or blank when the packets decide.
  def hardiness_by_hand
    hardiness if hardiness_source == 'manual'
  end

  # A level sets it by hand, and it is kept from then on. Blank hands it back to the packets.
  def hardiness_by_hand=(level)
    if level.blank? || level == Hardiness::UNKNOWN
      self.hardiness_source = nil if hardiness_source == 'manual'
      @hardiness_from_packets = true
    else
      self.hardiness = level
      self.hardiness_source = 'manual'
    end
  end

  # Keeps how much frost the crop takes: what most of the packets of the crop and its varieties say, else unknown.
  # A value set by hand is kept. Written without callbacks or history, as a figure worked out from the packets
  # and not someone's edit.
  def update_hardiness
    return if hardiness_source == 'manual'

    level = Hardiness.most_common(Seed.of_crop(self).where.not(hardiness: Hardiness::UNKNOWN).group(:hardiness).count)
    update_columns(hardiness: level, hardiness_source: (level == Hardiness::UNKNOWN ? nil : 'seed_packets')) # rubocop:disable Rails/SkipsModelValidations
  end

  # returns hash indicating whether this crop is grown in
  # sun/semi-shade/shade
  # key: sunniness (eg. 'sun')
  # value: count of how many times it's been used by plantings
  def sunniness
    count_uses_of_property 'sunniness'
  end

  # returns a hash of propagation methods (seed, seedling, etc),
  # key: propagation method (eg. 'seed')
  # value: count of how many times it's been used by plantings
  def planted_from
    count_uses_of_property 'planted_from'
  end

  # returns a hash of most harvested plant parts (fruit, seed, etc)
  # key: plant part (eg. 'fruit')
  # value: count of how many times it's been used by harvests
  def popular_plant_parts
    PlantPart.joins(:harvests)
      .where("crop_id = ?", id)
      .order(count_harvests_id: :desc)
      .group("plant_parts.id", "plant_parts.name")
      .count("harvests.id")
  end

  def perennial?
    perennial == true
  end

  def annual?
    perennial == false
  end

  def interesting?
    photos.size >= 3 || plantings_count >= 3
  end

  def pending?
    approval_status == "pending"
  end

  def approved?
    approval_status == "approved"
  end

  def rejected?
    approval_status == "rejected"
  end

  def approval_statuses
    %w(rejected pending approved)
  end

  def reasons_for_rejection
    ["already in database", "not edible", "not enough information", "other"]
  end

  def rejection_explanation
    return rejection_notes if reason_for_rejection == "other"

    reason_for_rejection
  end

  # The job templates to offer for this crop: its own and, for a variety, those of its parent.
  def published_job_templates
    CropJobTemplate.published.for_crop(self)
  end

  # The seed packets of this crop and of its varieties that give a figure for a
  # packet fact such as row_spacing. A packet that leaves it blank, or says zero,
  # gives none.
  def seeds_with(attribute)
    Seed.of_crop(self).where.not(attribute => [nil, 0])
  end

  # The median of that figure across those packets, or nil when there are none.
  def seed_median(attribute)
    seeds_with(attribute).median(attribute)
  end

  # The months to sow in, from the seed packets of this crop and of its varieties,
  # for the southern hemisphere, as the seasons are opposite: the northern months
  # are six months on from them. A packet's months are the owner's, so a northern
  # packet is moved six months to compare with the southern ones, and the months at
  # least half of the packets give are the answer. Packets whose owner hasn't said
  # where they live can't say which hemisphere they mean, and are left out. Empty
  # when no packet says anything.
  def seed_sow_months
    packets = Seed.of_crop(self).joins(:owner).where.not(members: { latitude: nil }).where('cardinality(seeds.sow_months) > 0')
    total = packets.count
    return [] if total.zero?

    months = Seed.connection.select_rows(<<~SQL.squish)
      SELECT month, COUNT(*) FROM (
        SELECT DISTINCT packets.id,
          CASE WHEN packets.latitude < 0 THEN sown ELSE ((sown + 5) % 12) + 1 END AS month
        FROM (#{packets.select('seeds.id', 'seeds.sow_months', 'members.latitude').to_sql}) packets,
          unnest(packets.sow_months) AS sown
      ) per_packet GROUP BY month HAVING COUNT(*) * 2 >= #{total.to_i}
    SQL
    months.map { |month, _count| month.to_i }.sort
  end

  # The months to sow in the northern hemisphere: the southern ones, six months on.
  def sow_months_northern
    opposite_months(sow_months)
  end

  def median_sow_months_northern
    opposite_months(median_sow_months)
  end

  # Keeps the medians from seed packets on the crop, so the crop page needn't work
  # them out each time. Written without callbacks or history: they are figures
  # worked out from the packets, not someone's edit of the crop.
  def update_seed_medians
    update_columns( # rubocop:disable Rails/SkipsModelValidations
      median_row_spacing: seed_median(:row_spacing), median_sow_months: seed_sow_months,
      **PACKET_RANGES.index_with { |attribute| seed_median(attribute) }.transform_keys { |attribute| :"median_#{attribute}" }
    )
  end

  # Works out hardiness for every crop from its packets.
  def self.update_all_hardiness
    find_each(&:update_hardiness)
  end

  def update_medians
    plantings.each(&:update_harvest_days!)
    update_lifespan_medians
    update_harvest_medians
  end

  def update_lifespan_medians
    # Median lifespan of plantings
    update(median_lifespan: Planting.where(crop: self).median(:lifespan))
  end

  def update_harvest_medians
    update(median_days_to_first_harvest: Planting.where(crop: self).median(:days_to_first_harvest))
    update(median_days_to_last_harvest: Planting.where(crop: self).median(:days_to_last_harvest))
  end

  def self.case_insensitive_name(name)
    where(["lower(crops.name) = :value", { value: name.downcase }])
  end

  # Ids of this crop and every variety below it, however deep, so a tomato's
  # page can include a striped heirloom tomato's plantings and photos.
  def self_and_descendant_ids
    ids = [id]
    level = ids
    while level.any?
      level = Crop.where(parent_id: level).where.not(id: ids).pluck(:id)
      ids += level
    end
    ids
  end

  def plantings_with_varieties
    Planting.where(crop_id: self_and_descendant_ids)
  end

  # Like photos, but also those of the varieties. Photos of seed packets are still left out.
  def photos_with_varieties
    Photo.where(id: PhotoAssociation.where(crop_id: self_and_descendant_ids).select(:photo_id))
      .where.not(id: PhotoAssociation.of_packets.select(:photo_id))
  end

  # These crops and the crops they are varieties of.
  def self.with_parents
    crops = all
    crops.or(unscoped.where(id: crops.select(:parent_id)))
  end

  # Works out the medians from seed packets for every crop that has packets, and the
  # crops they are varieties of.
  def self.update_all_seed_medians
    where(id: Seed.unscoped.select(:crop_id)).with_parents.find_each(&:update_seed_medians)
  end

  def all_companions
    @all_companions ||= if parent
                          (companions + parent.all_companions).uniq
                        else
                          companions
                        end
  end

  before_validation :release_slug, if: :rejected?
  before_destroy :destroy_reverse_companionships
  after_save :update_hardiness, if: :hardiness_from_packets?

  def should_generate_new_friendly_id?
    slug.blank? || (!rejected? && name_changed?)
  end

  private

  def hardiness_from_packets?
    @hardiness_from_packets
  end

  # The same part of the year in the other hemisphere: March is September.
  def opposite_month(month)
    ((month + 5) % 12) + 1
  end

  def opposite_months(months)
    months.map { |month| opposite_month(month) }.sort
  end

  def release_slug
    return if slug.blank?
    return if slug.include?('-rejected-')

    suffix = id || SecureRandom.hex(4)
    self.slug = "#{slug}-rejected-#{suffix}"
  end

  def destroy_reverse_companionships
    CropCompanion.where(crop_b: self).destroy_all
  end

  def count_uses_of_property(col_name)
    plantings.unscoped
      .where(crop_id: id)
      .where.not(col_name => nil)
      .group(col_name)
      .count
  end

  def must_be_rejected_if_rejected_reasons_present
    return if rejected?
    return unless reason_for_rejection.present? || rejection_notes.present?

    errors.add(:approval_status, :rejection_reason_required)
  end

  def sow_months_are_months
    errors.add(:sow_months, :inclusion) unless sow_months.all? { |month| (1..12).cover?(month) }
  end

  def must_have_meaningful_reason_for_rejection
    return unless reason_for_rejection == "other" && rejection_notes.blank?

    errors.add(:rejection_notes, :rejection_notes_required)
  end
end
