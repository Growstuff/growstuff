# frozen_string_literal: true

# The climate at the member's home through the four seasons, every crop gardeners at
# their latitude are sowing this month, and the switch for turning those suggestions
# off or on.
class SuggestionsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def index
    @dashboard = MemberDashboard.new(current_member)
    @crops = @dashboard.easy_to_sow(40)
    @climate = SeasonalClimate.for(current_member)
  end

  def update
    current_member.update_columns(suggest_crops: params[:suggest] == 'true') # rubocop:disable Rails/SkipsModelValidations
    redirect_back_or_to suggestions_path, notice: t(current_member.suggest_crops ? '.enabled' : '.disabled')
  end
end
