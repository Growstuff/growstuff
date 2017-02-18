class AdminController < ApplicationController
  respond_to :html

  def index
    authorize! :manage, :all
  end

  def newsletter
    authorize! :manage, :all
    @members = Member.confirmed.wants_newsletter.all
  end
end
