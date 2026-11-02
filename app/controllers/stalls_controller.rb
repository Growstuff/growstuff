# frozen_string_literal: true

# A member's garden stall, shared by link. Only the owner sees it while it is
# closed.
class StallsController < ApplicationController
  include FeatureGated

  require_feature :garden_stall
  before_action :authenticate_member!, only: :update

  def show
    @member = Member.confirmed.find_by!(slug: params[:member_slug])
    @owner = @member == current_member
    @stall = @member.stall || @member.build_stall
    raise ActiveRecord::RecordNotFound unless @stall.open? || @owner

    # The shutter rolls up when the owner arrives from opening it.
    @opening = @owner && @stall.open? && flash.notice.present?
  end

  # The owner choosing where friends can be.
  def update
    stall = current_member.stall!
    if stall.update(params.expect(stall: %i(claim_area postage)))
      redirect_to member_stall_path(current_member), notice: t('.updated')
    else
      redirect_to member_stall_path(current_member), alert: stall.errors.full_messages.to_sentence
    end
  end
end
