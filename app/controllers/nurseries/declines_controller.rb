# frozen_string_literal: true

# A member saying they don't raise seedlings, so we stop asking about a nursery.
module Nurseries
  class DeclinesController < ApplicationController
    before_action :authenticate_member!

    def create
      current_member.decline_nursery!
      redirect_to member_gardens_path(current_member), notice: t('gardens.nursery_declined')
    end
  end
end
