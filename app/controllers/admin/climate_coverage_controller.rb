# frozen_string_literal: true

module Admin
  # Which members and gardens have climate data for where they are: see ClimateCoverage.
  class ClimateCoverageController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :manage, :all }

    def members
      list(MemberClimateCoverage.new(Member.kept), Member.kept.order(:login_name))
    end

    def gardens
      owned = Garden.where(owner: Member.kept)
      list(ClimateCoverage.new(owned), owned.includes(:owner).order(:name))
    end

    private

    # Sets what the views read: the counts for every status, and the records of the status picked, or all, a page at a time.
    def list(coverage, ordered)
      @coverage = coverage
      @counts = @coverage.counts
      @status = ClimateCoverage::STATUSES.find { |status| status == params[:status] }
      ordered = ordered.where(id: @coverage.ids(@status)) if @status
      @records = ordered.paginate(page: params[:page])
    end
  end
end
