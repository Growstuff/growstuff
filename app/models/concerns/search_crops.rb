# frozen_string_literal: true

# Crop search, done in Postgres. A crop matches when a word of its name, an
# alternate name or a scientific name starts with the term, or when one of them
# is similar to it (pg_trgm), which is what forgives typos and plurals.
module SearchCrops
  extend ActiveSupport::Concern

  MIN_SIMILARITY = 0.35
  NAME_WEIGHT = 5
  PLANTED_BOOST = 5

  NAMES_SQL = <<~SQL.squish
    SELECT id AS crop_id, name, #{NAME_WEIGHT} AS weight FROM crops
    UNION ALL SELECT crop_id, name, 1 FROM alternate_names
    UNION ALL SELECT crop_id, name, 1 FROM scientific_names
  SQL

  included do
    ####################################
    # Elastic search configuration. Nothing searches the index any more, but it
    # is still kept up to date.
    searchkick word_start:     %i(name description alternate_names scientific_names),
               searchable:     %i(name descriptions alternate_names scientific_names),
               case_sensitive: false,
               merge_mappings: true,
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   created_at:      { type: :integer },
                   plantings_count: { type: :integer },
                   harvests_count:  { type: :integer },
                   photos_count:    { type: :integer }
                 }
               }

    # Special scope to control if it's in the search index
    scope :search_import, -> { approved }

    def should_index?
      approved?
    end

    def search_data
      {
        name:,
        description:,
        slug:,
        alternate_names:  alternate_names.pluck(:name),
        scientific_names: scientific_names.pluck(:name),
        photos_count:     photo_associations_count,
        # boost the crops that are planted the most
        plantings_count:,
        harvests_count:,
        # boost this crop for these members
        planters_ids:     plantings.distinct.pluck(:owner_id),
        has_photos:       photo_associations_count.positive?,
        thumbnail_url:,
        scientific_name:  default_scientific_name&.name,
        created_at:       created_at.to_i
      }
    end

    # Approved crops matching the term, best first. A blank term matches them all.
    # Crops with more plantings rank higher, and so do crops the member has planted.
    scope :search_by_name, lambda { |term, member: nil|
      term = term.to_s.squish
      next approved.order(Arel.sql(SearchCrops.popularity_sql)) if term.blank?

      approved
        .joins("INNER JOIN (#{SearchCrops.matches_sql(term)}) matches ON matches.crop_id = crops.id")
        .order(Arel.sql("#{SearchCrops.rank_sql(member)} DESC"), :name)
    }
  end

  def self.matches_sql(term)
    like = ApplicationRecord.sanitize_sql_like(term.downcase)
    ApplicationRecord.sanitize_sql_array([<<~SQL.squish, { term: term, starts: "#{like}%", word: "% #{like}%", hyphen: "%-#{like}%", min: MIN_SIMILARITY }])
      SELECT crop_id, MAX(weight * score) AS score
      FROM (
        SELECT crop_id, weight,
               CASE WHEN name_norm LIKE :starts OR name_norm LIKE :word OR name_norm LIKE :hyphen
                    THEN 1.0 ELSE word_similarity(unaccent(lower(:term)), name_norm) END AS score
        FROM (SELECT crop_id, weight, unaccent(lower(name)) AS name_norm FROM (#{NAMES_SQL}) names) normalised
      ) scored
      WHERE score >= :min
      GROUP BY crop_id
    SQL
  end

  def self.rank_sql(member)
    sql = "matches.score * (1 + LN(1 + crops.plantings_count))"
    return sql unless member

    own = ApplicationRecord.sanitize_sql_array(
      ["(SELECT COUNT(*) FROM plantings WHERE plantings.crop_id = crops.id AND plantings.owner_id = ?)", member.id]
    )
    "#{sql} * (1 + #{PLANTED_BOOST} * LN(1 + #{own}))"
  end

  def self.popularity_sql
    "(1 + LN(1 + crops.plantings_count)) * (1 + LN(1 + crops.harvests_count)) DESC, crops.name"
  end
end
