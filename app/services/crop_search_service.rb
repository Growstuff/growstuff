# frozen_string_literal: true

class CropSearchService
  # Crop.search(string)
  def self.search(query, page: 1, per_page: 12, current_member: nil)
    search_params = {
      page:         page,
      per_page:     per_page,
      fields:       %i(name^5 alternate_names scientific_names),
      match:        :word_start,
      boost_by:     [:plantings_count],
      includes:     %i(scientific_names alternate_names),
      misspellings: { edit_distance: 2 },
      load:         false
    }
    # prioritise crops the member has planted
    search_params[:boost_where] = { planters_ids: current_member.id } if current_member

    Crop.search(query, search_params)
  end

  def self.random_with_photos(limit)
    body = {
      "query": {
        "function_score": {
          "query":        { "query_string": { "query": 'has_photos:true' } },
          "random_score": { "seed": DateTime.now.to_i }
        }
      }
    }
    Crop.search(
      limit: limit,
      load:  false,
      body:  body
    )
  end

  def self.recent(limit)
    Crop.search(
      limit:    limit,
      load:     false,
      boost_by: { created_at: { factor: 100 } } # default factor is 1
    )
  end
end
