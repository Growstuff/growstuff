# frozen_string_literal: true

module Admin
  # Every EcoCrop record, and the crops each has been matched to, so crop wranglers can see which are still unmatched.
  class EcocropDataController < ApplicationController
    FILTERS = %w(matched unmatched).freeze

    before_action :authenticate_member!
    before_action { authorize! :wrangle, Crop }

    def index
      @filter = params[:filter] if FILTERS.include?(params[:filter])
      @query = params[:q].to_s.strip
      @records = EcocropData.includes(:crops).order(:scientificname)
      @records = @records.public_send(@filter) if @filter
      @records = @records.search(@query) if @query.present?
      @records = @records.paginate(page: params[:page], per_page: 50)
      @counts = { all: EcocropData.count, matched: EcocropData.matched.count }
    end
  end
end
