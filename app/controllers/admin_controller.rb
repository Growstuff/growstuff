class AdminController < ApplicationController
  def index
    authorize! :manage, :all
    respond_to do |format|
      format.html # index.html.haml
    end
  end
end
