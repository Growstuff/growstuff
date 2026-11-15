# frozen_string_literal: true

# What other members have handed over to this one, for them to say they received it: seedlings given to them, which go into one
# of their gardens, and packets of seed.
module Stalls
  class GiftsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def index
      handovers = StallHandovers.new(current_member)
      @gifts = handovers.seedlings_to_receive
      @seed_gifts = handovers.seeds_to_receive
      @gardens = current_member.gardens.active.order_by_name
    end
  end
end
