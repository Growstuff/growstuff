class FollowsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  skip_load_resource only: :create

  # POST /follows
  def create
    @follow = current_member.follows.build(followed: Member.find(params[:followed]))

    if @follow.save
      flash[:notice] = "Followed #{@follow.followed.login_name}"
    else
      flash[:error] = "Already following or error while following."
    end
    redirect_back fallback_location: root_path
  end

  # DELETE /follows/1
  def destroy
    @follow = current_member.follows.find(params[:id])
    @unfollowed = @follow.followed
    @follow.destroy

    flash[:notice] = "Unfollowed #{@unfollowed.login_name}"
    redirect_to @unfollowed
  end

  private

  def follow_params
    params.permit(:id, :followed, :follower)
  end
end
