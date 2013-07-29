class HomeController < ApplicationController
  skip_authorize_resource

  def index
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    @member = current_member

    @recent_crops = Crop.recent.first(12)

    # choose 6 recently-signed-in members sort of at random
    @interesting_members = Member.interesting.limit(30).shuffle.first(6)

    @plantings = Planting.limit(15)

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
