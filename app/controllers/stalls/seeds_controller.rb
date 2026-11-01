# frozen_string_literal: true

# The member choosing which of their seed packets are on their garden stall.
module Stalls
  class SeedsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!
    before_action :load_stall

    def new
      @new_seed = Seed.new
      load_packets
    end

    # The ticked packets go on the stall, and so does a new one if they have
    # filled in a crop for it: it is recorded in their seed library first.
    def create
      @new_seed = new_seed
      return render_new_seed_errors if @new_seed && !@new_seed.save

      packets = current_member.seeds.where(id: params[:seed_ids]).to_a
      packets << @new_seed if @new_seed
      return redirect_to new_stall_seed_path, alert: t('.none') if packets.empty?

      @stall.put_seeds_on!(packets, offer: params[:offer].presence_in(StallSeed.offers.keys) || :free)
      redirect_to member_stall_path(current_member), notice: t('.added', count: packets.size)
    end

    def destroy
      @stall.stall_seeds.find_by!(seed: current_member.seeds.find(params[:id])).destroy
      redirect_to member_stall_path(current_member), notice: t('.removed')
    end

    private

    # Their packets not on the stall yet, to tick: the ones marked "will trade"
    # first, then the rest. Marking the rest happens when they go on the stall.
    def load_packets
      @query = params[:q].to_s.strip
      packets = current_member.seeds.current.joins(:crop).includes(:crop).order('crops.name', :variety)
        .where.not(id: @stall.stall_seeds.select(:seed_id))
      packets = packets.where('crops.name ILIKE :q OR seeds.variety ILIKE :q', q: "%#{Seed.sanitize_sql_like(@query)}%") if @query.present?
      @ready, @others = packets.partition(&:tradable)
    end

    # A packet they haven't recorded yet, if they filled any of it in.
    def new_seed
      fields = params.fetch(:seed, {}).permit(:crop_id, :variety, :quantity)
      return if fields.values.all?(&:blank?)

      current_member.seeds.build(fields.merge(source: 'my own seed saving', finished: false))
    end

    def render_new_seed_errors
      load_packets
      render :new, status: :unprocessable_content
    end

    def load_stall
      @stall = current_member.stall
      redirect_to member_stall_path(current_member) unless @stall&.open?
    end
  end
end
