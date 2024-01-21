# frozen_string_literal: true

module GbifData
  extend ActiveSupport::Concern

  included do
    def update_gbif_data!
      GbifService.new.update_crop(self)
    end
  end
end
