# frozen_string_literal: true

# A member opening their garden stall, or closing it again.
module Stalls
  class OpeningsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def create
      current_member.stall!.open!
      redirect_to member_stall_path(current_member), notice: t('.opened')
    end

    def destroy
      current_member.stall!.close!
      redirect_to member_stall_path(current_member), notice: t('.closed')
    end
  end
end
