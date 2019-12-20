# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :set_member, only: %i(index followers)
  load_and_authorize_resource
  skip_load_resource only: :create

  def create
    @follow = current_member.follows.build(followed: Member.find(params[:followed]))

    if @follow.save
      flash[:notice] = "Followed #{@follow.followed.login_name}"
    else
      flash[:error] = "Already following or error while following."
    end
    redirect_back fallback_location: root_path
  end

  def destroy
    @follow = current_member.follows.find(params[:id])
    @unfollowed = @follow.followed
    @follow.destroy

    flash[:notice] = "Unfollowed #{@unfollowed.login_name}"
    redirect_to @unfollowed
  end

  def index
    @follows = @member.followed.paginate(page: params[:page])
  end

  def followers
    @followers = @member.followers.paginate(page: params[:page])
  end

  private

  def set_member
    @member = Member.confirmed.find(params[:member_slug])
  end

  def follow_params
    params.permit(:id, :followed, :follower)
  end
end
