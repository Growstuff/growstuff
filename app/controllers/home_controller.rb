# frozen_string_literal: true

class HomeController < ApplicationController
  skip_authorize_resource
  respond_to :html

  def index
    # we were previously generating a lot of instance variables like
    # @members_count and @interesting_crops in here, but now we call
    # the relevant class methods directly in the view, so that fragment
    # caching will be effective.
    @layout_garden = layout_garden if member_signed_in?
  end

  def community_gardens; end

  private

  # The garden the home page's invitation to the layout tool sends a member to:
  # their active garden with the most growing in it, so there is something to
  # arrange, and alphabetically between ones with the same.
  def layout_garden
    gardens = current_member.gardens.active.to_a
    growing = Planting.current.where(garden_id: gardens.map(&:id)).group(:garden_id).count
    gardens.min_by { |garden| [-growing.fetch(garden.id, 0), garden.name.downcase] }
  end
end
