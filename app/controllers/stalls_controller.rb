# frozen_string_literal: true

# A member's garden stall, shared by link. Only the owner sees it while it is
# closed.
class StallsController < ApplicationController
  include FeatureGated

  require_feature :garden_stall

  def show
    @member = Member.confirmed.find_by!(slug: params[:member_slug])
    @owner = @member == current_member
    @stall = @member.stall || @member.build_stall
    raise ActiveRecord::RecordNotFound unless @stall.open? || @owner

    # The shutter rolls up when the owner arrives from opening it.
    @opening = @owner && @stall.open? && flash.notice.present?
  end
end
