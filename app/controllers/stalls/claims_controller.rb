# frozen_string_literal: true

# A friend claiming a packet of seed or an offered seedling on someone's garden stall, or giving it back.
module Stalls
  class ClaimsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!
    before_action :load_item

    def create
      claim = Claim.new(item_key => @item, member: current_member, note: params[:note].presence, here: params[:here])
      if claim.save
        redirect_to stall_path, notice: t('.claimed', crop: crop_name)
      else
        redirect_to stall_path, alert: claim.errors.full_messages.to_sentence
      end
    end

    # Only your own claim, and only until it has been handed over: the owner's release is a separate thing.
    def destroy
      claim = current_member.claims.find_by!(item_key => @item)
      return redirect_to stall_path, alert: t('.too_late') unless claim.undoable?

      claim.destroy
      redirect_to stall_path, notice: t('.undone', crop: crop_name)
    end

    # The claimer says they collected it, and for a seedling which garden it goes into.
    def received
      claim = current_member.claims.find_by!(item_key => @item)
      garden = current_member.gardens.active.find_by(id: params[:garden_id])
      if claim.receive(garden)
        redirect_to stall_path, notice: t(claim.completed? ? '.received_done' : '.received', crop: crop_name)
      else
        redirect_to stall_path, alert: claim.errors.full_messages.to_sentence
      end
    end

    # The owner says they handed it over to whoever claimed it.
    def given
      claim = @item.claim
      raise ActiveRecord::RecordNotFound unless claim && @item.stall.member == current_member

      if claim.give
        redirect_to stall_path, notice: t(claim.completed? ? '.given_done' : '.given', crop: crop_name, name: claim.member)
      else
        redirect_to stall_path, alert: claim.errors.full_messages.to_sentence
      end
    end

    private

    # The packet, or the seedling, the claim is on: whichever the route is nested under.
    def load_item
      @item = params[:stall_seed_id] ? StallSeed.find(params[:stall_seed_id]) : StallPlanting.find(params[:stall_planting_id])
      raise ActiveRecord::RecordNotFound unless @item.stall.open?
    end

    def item_key
      @item.is_a?(StallSeed) ? :stall_seed : :stall_planting
    end

    def crop_name
      @item.is_a?(StallSeed) ? @item.seed.crop_name : @item.planting.display_name
    end

    def stall_path
      member_stall_path(@item.stall.member)
    end
  end
end
