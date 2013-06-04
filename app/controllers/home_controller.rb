class HomeController < ApplicationController
  skip_authorize_resource

  def index
    @member_count   = Member.confirmed.count
    @crop_count     = Crop.count
    @planting_count = Planting.count
    @garden_count   = Garden.count

    @interesting_members = Member.interesting.limit(6)

    # customise what we show on the homepage based on whether you're
    # logged in or not.
    @member = current_member
    @plantings = Planting.limit(15)
    @posts = Post.limit(10)

    respond_to do |format|
      format.html # index.html.haml
    end
  end

end
