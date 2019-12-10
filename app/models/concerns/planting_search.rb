module PlantingSearch
  extend ActiveSupport::Concern

  included do
    searchkick

    scope :search_import, -> { includes(:owner, :crop) }

    def search_data
      {
        slug:             slug,
        crop_slug:        crop.slug,
        crop_name:        crop.name,
        crop_id:          crop_id,
        owner_id:         owner_id,
        owner_name:       owner.login_name,
        planted_from:     planted_from,
        photos_count:     photos.size,
        harvests_count:   harvests.size,
        has_photos:       photos.size.positive?,
        active:           active?,
        thumbnail_url:    default_photo&.thumbnail_url,
        percentage_grown: percentage_grown.to_i,
        created_at:       created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*',
             limit:    limit,
             where:    {
               photos_count: { gt: 0 }
             },
             boost_by: [:created_at],
             load:     false)
    end
  end
end
