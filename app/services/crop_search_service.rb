# frozen_string_literal: true

class CropSearchService
  # Crop.search(string)
  def self.search(query, page: 1, per_page: 12, current_member: nil, **options)
    search_params = {
      page:,
      per_page:,
      fields:       %i(name^5 alternate_names scientific_names),
      match:        :word_start,
      boost_by:     [:plantings_count],
      includes:     %i(scientific_names alternate_names),
      misspellings: { edit_distance: 2 },
      load:         false
    }.merge(options)
    # prioritise crops the member has planted
    search_params[:boost_where] = { planters_ids: current_member.id } if current_member

    Crop.search(query, **search_params)
  end
end
