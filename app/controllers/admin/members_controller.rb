module Admin
  class MembersController < ApplicationController
    before_action :auth!
    def index
      @members = Member.order(:login_name).paginate(page: params[:page])
    end

    private

    def auth!
      authorize! :manage, :all
    end
  end
end
