# frozen_string_literal: true

# "Not interested" on a suggested person: the friends and neighbours page
# stops suggesting them.
class MemberDismissalsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def create
    member = Member.confirmed.find(params.require(:member_id))
    current_member.member_dismissals.find_or_create_by!(dismissed: member)
    redirect_back_or_to neighbours_path, notice: t('.dismissed', name: member.login_name)
  end
end
