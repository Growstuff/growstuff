# frozen_string_literal: true

# A member opening their garden stall, or closing it again.
module Stalls
  class OpeningsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def create
      current_member.stall!.open!
      flash[:stall_opened] = true
      redirect_to member_stall_path(current_member)
    end

    def destroy
      current_member.stall!.close!
      redirect_to member_stall_path(current_member), notice: t('.closed')
    end
  end
end
