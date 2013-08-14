class HomeController < ApplicationController
  skip_authorize_resource

  def index
    # for the stats partial
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    @crops        = Crop.interesting.first(6)
    @recent_crops = Crop.recent.limit(12)
    @plantings    = Planting.interesting.first(4)
    @seeds        = Seed.interesting.first(6)
    @members      = Member.interesting.first(6)

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
