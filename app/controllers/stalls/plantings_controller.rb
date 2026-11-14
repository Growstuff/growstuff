# frozen_string_literal: true

# The member recording seedlings from their nursery they have given away: which, to whom (an email address, or a Fediverse
# or Bluesky handle), and when. It doesn't need the stall to be open: it is a record, as much as an offer.
module Stalls
  class PlantingsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    STATUSES = %w(given offered).freeze

    def new
      @seedlings = giveable
      @kind = StallPlanting::KINDS.first
      @status = params[:status].presence_in(STATUSES) || 'given'
      load_offered_ids
    end

    # Seedlings are either given to someone, or put on the stall for now with nobody to give them to yet.
    def create
      @kind = params[:recipient_kind].to_s
      @status = params[:status].presence_in(STATUSES) || 'given'
      plantings = giveable.where(id: params[:planting_ids])
      return redirect_to new_stall_planting_path, alert: t('.none') if plantings.none?

      record(plantings.to_a)
      redirect_to member_stall_path(current_member), notice: t(".#{@status}", count: plantings.size)
    rescue ActiveRecord::RecordInvalid => e
      @seedlings = giveable
      load_offered_ids
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end

    # Takes a seedling off the stall that nobody has been given yet. Once given it is a record, and stays.
    def destroy
      current_member.stall!.stall_plantings.offered.find(params[:id]).destroy
      redirect_to member_stall_path(current_member), notice: t('.removed')
    end

    private

    def record(plantings)
      stall = current_member.stall!
      if @status == 'offered'
        stall.offer_seedlings!(plantings)
      else
        stall.give_away!(plantings, kind: @kind, recipient: params[:recipient].to_s, on: given_on)
      end
    end

    # Which of the seedlings are on their stall already, to say so beside them.
    def load_offered_ids
      @offered_ids = current_member.stall&.seedlings_on_offer&.pluck(:planting_id).to_a
    end

    # The seedlings in their nursery, newest sown first: only those are offered.
    def giveable
      current_member.plantings.current.includes({ crop: :parent }, :garden).joins(:garden).merge(Garden.nurseries)
        .order(planted_at: :desc, id: :desc)
    end

    # The day they gave them: today unless they said otherwise, and never in the future.
    def given_on
      day = Date.iso8601(params[:given_on].to_s)
      [day, Time.zone.today].min.in_time_zone.change(hour: 12)
    rescue Date::Error
      Time.current
    end
  end
end
