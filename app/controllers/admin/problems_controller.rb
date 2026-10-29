# frozen_string_literal: true

module Admin
  class ProblemsController < ApplicationController
    before_action :ensure_feature_enabled!
    before_action :authenticate_member!
    before_action :admin!
    load_and_authorize_resource
    respond_to :html
    responders :flash

    def index
      @problems = Problem.all.order(:title).paginate(page: params[:page])
      respond_with @problems
    end

    def show
      respond_with @problem
    end

    def new
      @problem = Problem.new
      @problem.scientific_names.build
      @problem.alternate_names.build
      respond_with @problem
    end

    def edit
      @problem.scientific_names.build if @problem.scientific_names.empty?
      @problem.alternate_names.build if @problem.alternate_names.empty?
      respond_with @problem
    end

    def create
      @problem = Problem.new(problem_params)
      assign_creators(@problem)
      @problem.save
      respond_with @problem, location: admin_problems_path
    end

    def update
      @problem.attributes = problem_params
      assign_creators(@problem)
      @problem.save
      respond_with @problem, location: admin_problems_path
    end

    def destroy
      @problem.destroy
      respond_with @problem, location: admin_problems_path, notice: "Problem was successfully deleted"
    end

    private

    def assign_creators(problem)
      return unless current_member

      problem.scientific_names.each { |sn| sn.creator ||= current_member }
      problem.alternate_names.each { |an| an.creator ||= current_member }
    end

    def ensure_feature_enabled!
      raise ActiveRecord::RecordNotFound unless Feature.enabled?(:problems)
    end

    def admin!
      authorize! :manage, Problem
    end

    def problem_params
      params.require(:problem).permit(
        :title,
        :description,
        :problem_type,
        scientific_names_attributes: %i(id name gbif_key gbif_rank gbif_status wikidata_id _destroy),
        alternate_names_attributes: %i(id name language _destroy)
      )
    end
  end
end
