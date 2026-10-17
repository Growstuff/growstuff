# frozen_string_literal: true

# Moving seedlings from the nursery into a garden: which batches, how many of
# each, which garden and when.
module Nurseries
  class PlantOutsController < ApplicationController
    include NurseryScoped

    before_action :set_batches_and_gardens, only: %i(new create)

    # Anything left of the batches just moved, to keep in the nursery or finish.
    def show
      @garden = current_member.gardens.find_by(slug: params[:garden])
      @count = params[:count].to_i
      @moved = @nursery.plantings.current.where(id: params[:batches].to_s.split(',')).includes(:crop).order(:planted_at, :id)
      redirect_to member_gardens_path(current_member) if @moved.empty?
    end

    def new; end

    def create
      garden = @gardens.find_by(slug: params[:garden_slug])
      transplants = garden ? @nursery.plant_out(quantities, into: garden, on: planted_on) : []
      return redirect_after(garden, transplants) if transplants.any?

      flash.now[:alert] = t(garden ? 'gardens.plant_out_nothing' : 'gardens.plant_out_no_garden')
      render :new, status: :unprocessable_entity
    end

    private

    def set_batches_and_gardens
      @batches = @nursery.plantings.current.includes(:crop).order(:planted_at, :id)
      @gardens = current_member.gardens.active.not_nurseries.order_by_name
    end

    # The ticked batches, each with how many of it to plant out.
    def quantities
      ticked = Array(params[:batch_ids]).map(&:to_i)
      @batches.select { |batch| ticked.include?(batch.id) }.index_with { |batch| params.dig(:quantities, batch.id.to_s).to_i }
    end

    def planted_on
      case params[:when]
      when 'yesterday' then Time.zone.yesterday
      when 'other' then Date.parse(params[:date].to_s)
      else Time.zone.today
      end
    rescue Date::Error
      Time.zone.today
    end

    # Straight back to the gardens when every batch went out; otherwise asks what
    # became of what is left.
    def redirect_after(garden, transplants)
      count = transplants.sum { |planting| planting.quantity || 1 }
      left = @nursery.plantings.current.where(id: transplants.map(&:transplanted_from_id)).ids
      return redirect_to member_gardens_path(current_member), notice: t('gardens.planted_out', count:, garden: garden.name) if left.empty?

      redirect_to nursery_plant_out_path(garden: garden.slug, count:, batches: left.join(','))
    end
  end
end
