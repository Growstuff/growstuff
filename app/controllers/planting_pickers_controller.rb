# frozen_string_literal: true

# The member's plantings as the record harvest and save seeds dialogs list
# them, for the links that are not on the home page.
class PlantingPickersController < ApplicationController
  before_action :authenticate_member!

  def show
    render json: helpers.planting_picker_props(MemberDashboard.new(current_member))
  end
end
