# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :set_member, only: %i(index followers)
  load_and_authorize_resource
  skip_load_resource only: :create

  def index
    @pagy, @follows = pagy(@member.followed)
  end

  def create
    @follow = current_member.follows.build(followed: Member.find(params[:followed]))

    if @follow.save
      flash[:notice] = t('messages.followed', name: @follow.followed.login_name)
    else
      flash[:error] = t('messages.follow_error')
    end
    redirect_back_or_to(root_path)
  end

  def destroy
    @follow = current_member.follows.find(params[:id])
    @unfollowed = @follow.followed
    @follow.destroy

    flash[:notice] = t('messages.unfollowed', name: @unfollowed.login_name)
    redirect_to @unfollowed
  end

  def followers
    @pagy, @followers = pagy(@member.followers)
  end

  private

  def set_member
    @member = Member.confirmed.find(params[:member_slug])
  end

  def follow_params
    params.permit(:id, :followed, :follower)
  end
end
