# frozen_string_literal: true

# The member choosing which of their seed packets are on their garden stall.
module Stalls
  class SeedsController < ApplicationController
    include FeatureGated

    require_feature :garden_stall
    before_action :authenticate_member!
    before_action :load_stall

    # Their packets not on the stall yet, to tick: the ones marked "will trade"
    # first, then the rest. Marking the rest happens when they go on the stall.
    def new
      @query = params[:q].to_s.strip
      packets = current_member.seeds.current.joins(:crop).includes(:crop).order('crops.name', :variety)
        .where.not(id: @stall.stall_seeds.select(:seed_id))
      packets = packets.where('crops.name ILIKE :q OR seeds.variety ILIKE :q', q: "%#{Seed.sanitize_sql_like(@query)}%") if @query.present?
      @ready, @others = packets.partition(&:tradable)
    end

    def create
      packets = current_member.seeds.where(id: params[:seed_ids])
      return redirect_to new_stall_seed_path, alert: t('.none') if packets.empty?

      @stall.put_seeds_on!(packets)
      redirect_to member_stall_path(current_member), notice: t('.added', count: packets.size)
    end

    def destroy
      @stall.stall_seeds.find_by!(seed: current_member.seeds.find(params[:id])).destroy
      redirect_to member_stall_path(current_member), notice: t('.removed')
    end

    private

    def load_stall
      @stall = current_member.stall
      redirect_to member_stall_path(current_member) unless @stall&.open?
    end
  end
end
