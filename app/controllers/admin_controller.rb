# frozen_string_literal: true

class AdminController < ApplicationController
  respond_to :html
  def index
    authorize! :manage, :all
  end
end
