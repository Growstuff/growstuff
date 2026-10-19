# frozen_string_literal: true

module PaginationHelper
  # Page links for a Pagy, or nothing when everything fits on one page.
  def pagination_nav(pagy)
    return if pagy.nil? || pagy.last <= 1

    pagy.series_nav(:bootstrap).html_safe # rubocop:disable Rails/OutputSafety -- pagy builds it from our own routes
  end

  # "Displaying crops 1-36 of 100 in total"
  def pagination_info(pagy, noun)
    pagy.info_tag(item_name: h(noun)).html_safe # rubocop:disable Rails/OutputSafety -- the noun is escaped above
  end
end
