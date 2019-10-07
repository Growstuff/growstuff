class LikesController < ApplicationController
  before_action :authenticate_member!
  respond_to :html, :json

  def create
    @like = Like.new(member: current_member, likeable: find_likeable)
    return failed(@like, message: 'Unable to like') unless @like.likeable && @like.save

    success(@like, liked_by_member: true, status_code: :created)
  end

  def destroy
    @like = Like.find_by(id: params[:id], member: current_member)
    return failed(@like, message: 'Unable to unlike') unless @like&.destroy

    success(@like, liked_by_member: false, status_code: :ok)
  end

  private

  def find_likeable
    if params[:post_id]
      Post.find(params[:post_id])
    elsif params[:photo_id]
      Photo.find(params[:photo_id])
    end
  end

  def render_json(like, liked_by_member: true)
    {
      id:              like.likeable.id,
      like_count:      like.likeable.likes.count,
      liked_by_member: liked_by_member,
      description:     ActionController::Base.helpers.pluralize(like.likeable.likes.count, 'like'),
      url:             like_path(like, format: :json)
    }
  end

  def success(like, liked_by_member: nil, status_code: nil)
    respond_to do |format|
      format.html { redirect_to like.likeable }
      format.json { render(json: render_json(like, liked_by_member: liked_by_member), status: status_code) }
    end
  end

  def failed(like, message)
    respond_to do |format|
      format.json { render(json: { 'error': message }, status: :forbidden) }
      format.html do
        flash[:error] = message
        if like&.likeable
          redirect_to like.likeable
        else
          redirect_to root_path
        end
      end
    end
  end
end
