class CropSearchService
  # Crop.search(string)
  def self.search(query, page: 1, per_page: 12, current_member: nil)
    if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"
      search_params = {
        page:     page,
        per_page: per_page,
        fields:   %i(name alternate_names scientific_names),
        match:    :word_start
      }
      # search_params[:boost_by] = [:plantings_count] # boost crops that are planted more often
      # prioritise crops the member has planted
      search_params[:boost_where] = { planters_ids: current_member.id } if current_member
      search_params[:includes] = %i(scientific_names alternate_names)

      Crop.search(query, search_params)
    else
      # if we don't have elasticsearch, just do a basic SQL query.
      # also, make sure it's an actual array not an activerecord
      # collection, so it matches what we get from elasticsearch and we can
      # manipulate it in the same ways (eg. deleting elements without deleting
      # the whole record from the db)
      matcher = "%#{query}%"
      matches = Crop.approved
        .left_outer_joins(:alternate_names, :scientific_names)
        .where("crops.name ILIKE ? OR alternate_names.name ILIKE ? OR scientific_names.name ILIKE ?",
          matcher, matcher, matcher)

      matches = matches.to_a
      # we want to make sure that exact matches come first, even if not
      # using elasticsearch (eg. in development)
      exact_match = Crop.approved.find_by(name: query)
      if exact_match
        matches.delete(exact_match)
        matches.unshift(exact_match)
      end
      matches.paginate(page: page, per_page: per_page)
    end
  end
end
