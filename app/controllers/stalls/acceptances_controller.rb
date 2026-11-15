# frozen_string_literal: true

# A member accepting a seedling that was given to them, into one of their gardens.
module Stalls
  class AcceptancesController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def create
      gift = StallPlanting.waiting_for(current_member).find(params[:gift_id])
      garden = current_member.gardens.active.find_by(id: params[:garden_id])
      if (received = gift.accept(current_member, garden))
        redirect_to received, notice: t('.accepted', crop: received.display_name)
      else
        redirect_to gifts_path, alert: gift.errors.full_messages.to_sentence
      end
    end
  end
end
