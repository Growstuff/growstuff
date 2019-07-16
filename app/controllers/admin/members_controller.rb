module Admin
  class MembersController < ApplicationController
    before_action :auth!

    def index
      @members = Member.order(:login_name).paginate(page: params[:page])
    end

    def destroy
      @member = Member.find_by!(slug: params[:id])
      @member.destroy
      redirect_to admin_members_path
    end

    private

    def auth!
      authorize! :manage, :all
    end
  end
end
