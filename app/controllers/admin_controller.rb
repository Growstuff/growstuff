# frozen_string_literal: true

class AdminController < ApplicationController
  respond_to :html
  def index
    authorize! :manage, :all
  end

  def newsletter
    authorize! :manage, :all
    @members = Member.confirmed.wants_newsletter.all
    respond_with @members
  end
end
