class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :count_entities
  
  def count_entities
    @crop_count = Crop.count
    @update_count = Update.count
    @member_count = User.count
  end    
end
