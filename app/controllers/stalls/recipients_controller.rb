# frozen_string_literal: true

# Members to pick from when saying who a seedling was given to: the ones matching what was typed.
module Stalls
  class RecipientsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    def index
      render json: StallRecipients.new(current_member).search(params[:q])
    end
  end
end
