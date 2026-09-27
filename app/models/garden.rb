# frozen_string_literal: true

class Garden < ApplicationRecord
  extend FriendlyId
  include Geocodable
  include PhotoCapable
  include Ownable

  friendly_id :garden_slug, use: %i(slugged finders)

  has_many :plantings, dependent: :destroy
  has_many :crops, through: :plantings
  has_many :activities, dependent: :destroy
  has_many :garden_collaborators, dependent: :destroy

  belongs_to :garden_type, optional: true

  # set up geocoding
  geocoded_by :location
  before_validation :strip_blanks
  after_validation :cleanup_area
  after_validation :geocode
  after_validation :empty_unwanted_geocodes
  after_validation :populate_wikidata_info, if: :will_save_change_to_location?
  after_save :mark_inactive_garden_plantings_as_finished

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :order_by_name, -> { order(Arel.sql("lower(name) asc")) }

  validates :location, length: { maximum: 255 }
  validates :slug, uniqueness: true

  validates :name, uniqueness: { scope: :owner_id }
  validates :name,
            format: { without: /\n/, message: :no_newlines },
            allow_blank: false, presence: true,
            length: { maximum: 255 }

  validates :area,
            numericality: { only_integer: false, greater_than_or_equal_to: 0 },
            allow_nil:    true

  # The layout grid. Capped so a bed's map stays a sensible number of cells to
  # draw, and so shrinking it can't quietly strand a planting off the edge.
  MAX_GRID_SIZE = 50
  validates :grid_columns, :grid_rows,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_GRID_SIZE }
  validate :grid_must_not_cut_off_plantings

  # The things on the layout that aren't plants. Each is a hash with a kind and a
  # position in grid cells (x, y). A line (a row, path, drip line, fence or
  # trellis) runs from there to (x2, y2), and an area (netting) is the rectangle
  # with those two corners. A label has text, and lines and areas can.
  LAYOUT_POINT_KINDS = %w(stone sprinkler tap stake label).freeze
  LAYOUT_SPAN_KINDS = %w(row path dripline fence trellis netting).freeze
  LAYOUT_FEATURE_KINDS = (LAYOUT_POINT_KINDS + LAYOUT_SPAN_KINDS).freeze
  MAX_LAYOUT_FEATURES = 200
  MAX_LAYOUT_TEXT = 40
  validate :layout_features_must_fit

  scope :located, lambda {
    where.not(gardens: { location: '' })
      .where.not(gardens: { latitude: nil })
      .where.not(gardens: { longitude: nil })
  }

  AREA_UNITS_VALUES = {
    "square metres" => "square metre",
    "square feet"   => "square foot",
    "hectares"      => "hectare",
    "acres"         => "acre"
  }.freeze
  validates :area_unit, inclusion:   { in:      AREA_UNITS_VALUES.values,
                                       message: :not_a_valid_area_unit },
                        allow_blank: true

  def cleanup_area
    self.area = nil if area&.zero?
    self.area_unit = nil if area.blank?
  end

  def garden_slug
    "#{owner.login_name}-#{name}".downcase.tr(' ', '-')
  end

  def to_s
    name
  end

  # When you mark a garden as inactive, all the plantings in it should be
  # marked as finished.  This automates that.
  def mark_inactive_garden_plantings_as_finished
    return unless active == false

    plantings.current.each do |p|
      p.finished = true
      p.save
    end
  end

  def reindex(refresh: false); end

  # Deactivate any gardens with no active plantings
  def self.archive!(time_limit: 3.years.ago, limit: 1000)
    Garden.active.where("gardens.updated_at < ?", time_limit).order(updated_at: :asc).limit(limit).each do |active_garden|
      unless active_garden.plantings.active.any?
        active_garden.active = false
        active_garden.save
      end
    end
  end

  def populate_wikidata_info
    return false if location.blank?

    wd_id = WikidataService.find_wikidata_id(location)
    return false if wd_id.blank?

    self.location_wikidata_id = wd_id
    temps = WikidataService.fetch_temps(wd_id)
    self.highest_temp_c = temps[:highest_temp_c]
    self.lowest_temp_c = temps[:lowest_temp_c]
    true
  end

  # How many cells the bed's layout grid has, for callers that just want the size.
  def grid_cells
    grid_columns * grid_rows
  end

  # What's wrong with a list of layout features, if anything, as messages. Used
  # by the layout's save as well as by validation, so a drag can be checked
  # without a full save (which would geocode the garden every time).
  def layout_feature_problems(features, columns: grid_columns, rows: grid_rows)
    return ['The garden features must be a list'] unless features.is_a?(Array)
    return ["A bed can have at most #{MAX_LAYOUT_FEATURES} garden features"] if features.size > MAX_LAYOUT_FEATURES

    features.filter_map { |feature| layout_feature_problem(feature, columns, rows) }.uniq
  end

  # The plants currently drawn on this bed's layout.
  def placed_plants
    Plant.placed.where(planting_id: plantings.current.select(:id))
  end

  # Every plant of every planting growing here, placed or not. What the layout
  # page may rearrange.
  def placed_or_owned_plants
    Plant.where(planting_id: plantings.current.select(:id))
  end

  # Gives each planting growing here its plants, the first time the layout is
  # used, rather than making them for every planting whether or not it ever
  # goes on a layout. Plantings that already have plants are left alone, and
  # so is one composted down to none. All in one insert.
  def prepare_layout
    now = Time.current
    rows = plantings.current.where.not(id: Plant.select(:planting_id)).flat_map do |planting|
      Array.new(planting.plant_count) { { planting_id: planting.id, created_at: now, updated_at: now } }
    end
    Plant.insert_all(rows) if rows.any? # rubocop:disable Rails/SkipsModelValidations
  end

  protected

  def strip_blanks
    self.name = name.strip unless name.nil?
  end

  # Shrinking the grid must not leave a placed plant hanging over the edge,
  # which would otherwise only show up as a plant missing from the map.
  def grid_must_not_cut_off_plantings
    return if new_record? || grid_columns.blank? || grid_rows.blank?
    return unless will_save_change_to_grid_columns? || will_save_change_to_grid_rows?
    return if placed_plants.outside_grid(grid_columns, grid_rows).none? &&
              layout_feature_problems(layout_features).empty?

    errors.add(:base, :grid_too_small_for_plantings)
  end

  def layout_features_must_fit
    return unless will_save_change_to_layout_features?

    layout_feature_problems(layout_features).each { |problem| errors.add(:base, problem) }
  end

  def layout_feature_problem(feature, columns, rows)
    known = feature.is_a?(Hash) && LAYOUT_FEATURE_KINDS.include?(feature['kind'])
    return "That isn't something that can go on the bed" unless known

    ends = [%w(x y)]
    ends << %w(x2 y2) if LAYOUT_SPAN_KINDS.include?(feature['kind'])
    return 'A garden feature is off the bed' unless ends.all? { |col, row| on_bed?(feature[col], feature[row], columns, rows) }

    text = feature['text'].to_s
    return 'A label needs something written on it' if feature['kind'] == 'label' && text.strip.empty?

    "A label or row name can be at most #{MAX_LAYOUT_TEXT} characters" if text.length > MAX_LAYOUT_TEXT
  end

  def on_bed?(col, row, columns, rows)
    col.is_a?(Numeric) && row.is_a?(Numeric) && col.between?(0, columns) && row.between?(0, rows)
  end
end
