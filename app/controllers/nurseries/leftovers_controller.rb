# frozen_string_literal: true

# Batches with nothing left to plant out, finished for the reason given.
module Nurseries
  class LeftoversController < ApplicationController
    include NurseryScoped

    def create
      reasons = params.fetch(:done, {}).permit!.to_h
      @nursery.plantings.where(id: reasons.keys).find_each { |batch| batch.finish_leftovers(reasons[batch.id.to_s]) }
      redirect_to member_gardens_path(current_member)
    end
  end
end
