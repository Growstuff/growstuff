class HomeController < ApplicationController
  skip_authorize_resource

  def index
    # for the stats partial
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    @crops        = Crop.interesting(6)
    @recent_crops = Crop.recent.limit(12)
    @plantings    = Planting.interesting(4)
    @seeds        = Seed.interesting(6)
    @members      = Member.interesting(6)

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
