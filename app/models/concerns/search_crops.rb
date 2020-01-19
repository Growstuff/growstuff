# frozen_string_literal: true

module SearchCrops
  extend ActiveSupport::Concern

  included do
    ####################################
    # Elastic search configuration
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
        name:             name,
        description:      description,
        slug:             slug,
        alternate_names:  alternate_names.pluck(:name),
        scientific_names: scientific_names.pluck(:name),
        photos_count:     photo_associations_count,
        # boost the crops that are planted the most
        plantings_count:  plantings_count,
        harvests_count:   harvests_count,
        # boost this crop for these members
        planters_ids:     plantings.pluck(:owner_id),
        has_photos:       photos.size.positive?,
        thumbnail_url:    thumbnail_url,
        scientific_name:  default_scientific_name&.name,
        created_at:       created_at.to_i
      }
    end
  end
end
