# frozen_string_literal: true

# "Not for me" on a suggested crop: the home page stops suggesting it, until
# they ask for their hidden suggestions back.
class CropDismissalsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def create
    crop = Crop.approved.find(params.require(:crop_id))
    current_member.crop_dismissals.find_or_create_by!(crop:)
    redirect_back_or_to root_path, notice: t('.dismissed', crop: crop.name)
  end

  def destroy_all
    current_member.crop_dismissals.destroy_all
    redirect_back_or_to root_path, notice: t('.restored')
  end
end
