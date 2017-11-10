class CropSearchService
  # Crop.search(string)
  def self.search(query)
    if ENV['GROWSTUFF_ELASTICSEARCH'] == "true"
      search_str = query.nil? ? "" : query.downcase
      response = Crop.__elasticsearch__.search( # Finds documents which match any field, but uses the _score from
        # the best field insead of adding up _score from each field.
        query: {
          multi_match: {
            query: search_str.to_s,
            analyzer: "standard",
            fields: ["name",
                     "scientific_names.scientific_name",
                     "alternate_names.name"]
          }
        },
        filter: {
          term: { approval_status: "approved" }
        },
        size: 50
      )
      response.records.to_a
    else
      # if we don't have elasticsearch, just do a basic SQL query.
      # also, make sure it's an actual array not an activerecord
      # collection, so it matches what we get from elasticsearch and we can
      # manipulate it in the same ways (eg. deleting elements without deleting
      # the whole record from the db)
      matches = Crop.approved.where("name ILIKE ?", "%#{query}%").to_a

      # we want to make sure that exact matches come first, even if not
      # using elasticsearch (eg. in development)
      exact_match = Crop.approved.find_by(name: query)
      if exact_match
        matches.delete(exact_match)
        matches.unshift(exact_match)
      end

      matches
    end
  end
end
