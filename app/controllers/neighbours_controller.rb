# frozen_string_literal: true

# What the gardeners a member follows, and the ones near them, are up to.
class NeighboursController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def show
    @neighbours = Neighbours.new(current_member, scope: params[:scope])
  end

  # The next small chunk of the feed, for "Show earlier days": its HTML, and
  # where to ask for the one after.
  def feed
    neighbours = Neighbours.new(current_member, scope: params[:scope], offset: params[:offset])
    after = params[:after].presence
    chunk = Rails.cache.fetch(neighbours.cache_key('chunk', neighbours.offset, after), expires_in: Neighbours::FEED_CACHE_FOR) do
      feed_chunk(neighbours, after)
    end
    render json: chunk
  end

  private

  def feed_chunk(neighbours, after)
    html = render_to_string(partial: 'neighbours/days', formats: [:html], locals: { neighbours:, after: after && Date.iso8601(after) })
    { html:, next: (helpers.next_feed_path(neighbours) if neighbours.more_feed?) }
  end
end
