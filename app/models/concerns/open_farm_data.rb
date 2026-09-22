# frozen_string_literal: true

module OpenFarmData
  extend ActiveSupport::Concern

  included do
    def of_photo
      fetch_attr('main_image_path')
    end

    # The icon OpenFarm had for this crop, if any. OpenFarm is gone, so these
    # are whatever was fetched before it closed; Crop#svg_icon decides which
    # icon a crop actually gets.
    def openfarm_svg_icon
      fetch_attr('svg_icon')
    end

    def tags_array
      fetch_attr('tags_array')
    end

    def common_names
      fetch_attr('common_names')
    end

    def binomial_name
      fetch_attr('binomial_name')
    end

    def main_image_path
      fetch_attr('main_image_path')
    end

    def processing_pictures
      fetch_attr('processing_pictures')
    end
  end

  def fetch_attr(key)
    return if openfarm_data.blank?

    openfarm_data.dig('attributes', key)
  end
end
