# frozen_string_literal: true

# Every crop gardeners at the member's latitude are sowing this month, and the
# switch for turning those suggestions off or on.
class SuggestionsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def index
    @dashboard = MemberDashboard.new(current_member)
    @crops = @dashboard.easy_to_sow(40)
  end

  def update
    current_member.update_columns(suggest_crops: params[:suggest] == 'true')
    redirect_back_or_to suggestions_path, notice: t(current_member.suggest_crops ? '.on' : '.off')
  end
end
