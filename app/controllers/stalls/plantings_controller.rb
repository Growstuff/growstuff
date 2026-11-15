# frozen_string_literal: true

# The member giving away seedlings from their nursery, or putting them on their stall: which, how many, and for those given,
# to whom and when. It doesn't need the stall to be open: it is a record, as much as an offer.
module Stalls
  class PlantingsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!

    STATUSES = %w(given offered).freeze
    RECIPIENT_FIELDS = %i(recipient_member_id recipient_name recipient_kind recipient).freeze
    # What the form shows again, if it can't be saved.
    FORM_FIELDS = (RECIPIENT_FIELDS + %i(given_on)).freeze

    def new
      @seedlings = giveable.to_a
      @status = params[:status].presence_in(STATUSES)
      @selected = params[:planting_ids].to_a.index_with { nil }
      @values = {}
      @recipients = StallRecipients.new(current_member)
    end

    # Seedlings are either given to someone, or put on the stall for now with nobody to give them to yet.
    def create
      @status = params[:status].presence_in(STATUSES) || 'given'
      plantings = giveable.where(id: params[:planting_ids]).to_a
      return redirect_to new_stall_planting_path(status: @status), alert: t('.none') if plantings.empty?

      record(plantings)
      redirect_to member_stall_path(current_member), notice: t(".#{@status}", count: plantings.size)
    rescue ActiveRecord::RecordInvalid => e
      render_form_again(e.record.errors.full_messages.to_sentence)
    end

    # Takes a seedling off the stall that nobody has been given yet. Once given it is a record, and stays.
    def destroy
      current_member.stall!.stall_plantings.offered.find(params[:id]).destroy
      redirect_to member_stall_path(current_member), notice: t('.removed')
    end

    private

    def record(plantings)
      stall = current_member.stall!
      quantities = params[:quantities]&.to_unsafe_h || {}
      if @status == 'offered'
        stall.offer_seedlings!(plantings, quantities:)
      else
        stall.give_away!(plantings, to: recipient_params, on: given_on, quantities:)
      end
    end

    # Who it went to: a member they picked, or a name, and how that person signs in, if they know.
    def recipient_params
      fields = params.slice(*RECIPIENT_FIELDS).permit(*RECIPIENT_FIELDS).to_h.symbolize_keys
      fields.delete(:recipient_kind) if fields[:recipient].blank?
      member = StallRecipients.new(current_member).pickable.find_by(id: fields.delete(:recipient_member_id))
      fields.transform_values(&:presence).merge(recipient_member: member)
    end

    def render_form_again(message)
      @seedlings = giveable.to_a
      @selected = params[:planting_ids].to_a.index_with { |id| params.dig(:quantities, id).presence&.to_i }
      @status = params[:status].presence_in(STATUSES)
      @values = params.slice(*FORM_FIELDS).permit(*FORM_FIELDS).to_h
      @recipients = StallRecipients.new(current_member)
      @errors = [message]
      render :new, status: :unprocessable_content
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
