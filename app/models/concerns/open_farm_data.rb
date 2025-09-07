# frozen_string_literal: true

module OpenFarmData
  extend ActiveSupport::Concern

  included do
    def of_photo
      fetch_attr('main_image_path')
    end

    def svg_icon
      icon = fetch_attr('svg_icon')
      return icon if icon.present?

      parent.svg_icon if parent.present?
    end

    def tags_array
      fetch_attr('tags_array')
    end

    def description
      fetch_attr('description')
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

    openfarm_data.fetch('attributes', {}).fetch(key, nil)
  end
end
