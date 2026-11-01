# frozen_string_literal: true

# A friend claiming a packet on someone's garden stall, or giving it back.
module Stalls
  class ClaimsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!
    before_action :load_stall_seed

    def create
      claim = Claim.new(stall_seed: @stall_seed, member: current_member, note: params[:note].presence)
      if claim.save
        redirect_to stall_path, notice: t('.claimed', crop: @stall_seed.seed.crop_name)
      else
        redirect_to stall_path, alert: claim.errors.full_messages.to_sentence
      end
    end

    # Only your own claim: the owner's release is a separate thing.
    def destroy
      current_member.claims.find_by!(stall_seed: @stall_seed).destroy
      redirect_to stall_path, notice: t('.undone', crop: @stall_seed.seed.crop_name)
    end

    private

    def load_stall_seed
      @stall_seed = StallSeed.find(params[:stall_seed_id])
      raise ActiveRecord::RecordNotFound unless @stall_seed.stall.open?
    end

    def stall_path
      member_stall_path(@stall_seed.stall.member)
    end
  end
end
