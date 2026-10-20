# frozen_string_literal: true

class CropSearchService
  # Approved crops matching the term, best first, paginated.
  def self.search(query, page: 1, per_page: 12, current_member: nil)
    Crop.search_by_name(query, member: current_member)
      .includes(:scientific_names, :alternate_names)
      .paginate(page:, per_page:)
  end
end
