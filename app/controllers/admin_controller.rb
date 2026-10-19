# frozen_string_literal: true

class AdminController < ApplicationController
  respond_to :html
  def index
    authorize! :manage, :all
  end

  def newsletter
    authorize! :manage, :all
    @pagy, @members = pagy(Member.confirmed.wants_newsletter, limit: 100)
    respond_with @members
  end
end
