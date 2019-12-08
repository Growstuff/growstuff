module CropSearch
  extend ActiveSupport::Concern

  included do
    ####################################
    # Elastic search configuration
    searchkick word_start: %i(name alternate_names scientific_names), case_sensitive: false if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"

    # Special scope to control if it's in the search index
    scope :search_import, -> { includes(:scientific_names, :photos) }

    def should_index?
      approved?
    end

    def search_data
      {
        name:             name,
        slug:             slug,
        alternate_names:  alternate_names.pluck(:name),
        scientific_names: scientific_names.pluck(:name),
        # boost the crops that are planted the most
        plantings_count:  plantings_count,
        # boost this crop for these members
        planters_ids:     plantings.pluck(:owner_id),
        has_photos:       photos.size.positive?,
        photo:            default_photo&.thumbnail_url,
        scientific_name:  default_scientific_name&.name,
        description:      description,
        created_at:       created_at
      }
    end
  end
end
