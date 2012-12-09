class HomeController < ApplicationController
  def index
    @crop_count = Crop.count
    @update_count = Update.count
    @member_count = User.count
  end
end
