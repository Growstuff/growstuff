# frozen_string_literal: true

module SearchActivities
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   active:     { type: :boolean },
                   created_at: { type: :integer }
                 }
               }

    def search_data
      {
        slug:,
        active:,
        finished:         finished?,
        name:,
        due_date:,
        category:,
        garden_id:,
        garden_name:      garden&.name,
        planting_id:,
        planting_name:    planting&.crop&.name,
        description:,

        # owner
        owner_id:,
        owner_login_name:,
        owner_slug:,

        # timestamps
        created_at:       created_at.to_i,
        updated_at:       updated_at.to_i
      }
    end

    def self.homepage_records(limit)
      records = []
      owners = []
      1..limit.times do
        where = {
          # photos_count: { gt: 0 },
          owner_id: { not: owners }
        }
        one_record = search('*',
                            limit:    1,
                            where:,
                            boost_by: [:created_at],
                            load:     false).first
        return records if one_record.nil?

        owners << one_record.owner_id
        records << one_record
      end
      records
    end
  end
end
