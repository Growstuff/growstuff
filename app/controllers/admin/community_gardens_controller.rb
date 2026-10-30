# frozen_string_literal: true

module Admin
  class CommunityGardensController < ApplicationController
    before_action :admin!
    load_and_authorize_resource
    respond_to :html
    responders :flash

    def index
      @community_gardens = CommunityGarden.all.order(:title).paginate(page: params[:page])
      respond_with @community_gardens
    end

    def show
      respond_with @community_garden
    end

    def new
      @community_garden = CommunityGarden.new
      respond_with @community_garden
    end

    def edit
      respond_with @community_garden
    end

    def create
      @community_garden = CommunityGarden.create(community_garden_params)
      respond_with @community_garden, location: admin_community_gardens_path
    end

    def update
      @community_garden.update(community_garden_params)
      respond_with @community_garden, location: admin_community_gardens_path
    end

    def destroy
      @community_garden.destroy
      respond_with @community_garden, location: admin_community_gardens_path, notice: "Community garden was successfully deleted"
    end

    private

    def admin!
      authorize! :manage, :all
    end

    def community_garden_params
      params.require(:community_garden).permit(:title, :website, :coordinates, :wikidata_id, :osm_id, :description, :email)
    end
  end
end
