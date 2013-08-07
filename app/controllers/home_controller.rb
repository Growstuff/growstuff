class HomeController < ApplicationController
  skip_authorize_resource

  def index
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    @member = current_member

    @recent_crops = Crop.recent.limit(12)
    @seeds = Seed.interesting(6)

    # choose 6 recently-signed-in members sort of at random
    @interesting_members = Member.interesting(6)

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
