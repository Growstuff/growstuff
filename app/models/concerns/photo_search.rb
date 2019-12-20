# frozen_string_literal: true

module PhotoSearch
  extend ActiveSupport::Concern

  included do
    searchkick

    scope :search_import, -> { includes(:owner, :crop, :plantings, :harvests, :seeds, P: posts) }

    def search_data
      {
        slug: slug,
        crops: crops.map(&:id),
        owner_id: owner_id,
        owner_name: owner.login_name,
        thumbnail_url: thumbnail_url,
        created_at: created_at.to_i
      }
    end
  end
end
