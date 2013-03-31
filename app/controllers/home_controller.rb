class HomeController < ApplicationController
  skip_authorize_resource

  def index
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
