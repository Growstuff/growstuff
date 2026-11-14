# frozen_string_literal: true

# The seedlings other members have given to this one: given to their email address, or a Fediverse or Bluesky handle they
# sign in with. They claim each into a garden of their own.
module Stalls
  class GiftsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def index
      @gifts = StallPlanting.waiting_for(current_member).includes(planting: :crop, stall: :member).newest_first
      @gardens = current_member.gardens.active.order_by_name
    end
  end
end
