class LikesController < ApplicationController
  before_action :authenticate_member!
  respond_to :html, :json

  def create
    @like = Like.new(member: current_member, likeable: find_likeable)
    unable_to_like(@like) unless @like.likeable && @like.save

    respond_to do |format|
      format.html { redirect_to @like.likeable }
      format.json do
        render(json: render_json(@like, liked_by_member: true),
               status: 201)
      end
    end
  end

  def destroy
    @like = Like.find_by(id: params[:id], member: current_member)
    unable_to_unlike(@like) unless @like && @like.destroy

    respond_to do |format|
      format.html { redirect_to @like.likeable }
      format.json do
        render(json: render_json(@like, liked_by_member: false),
               status: 200)
      end
    end
  end

  private

  def find_likeable
    Post.find(params[:post_id]) if params[:post_id]
  end

  def render_json(like, liked_by_member)
    {
      id: like.likeable.id,
      liked_by_member: liked_by_member,
      description: ActionController::Base.helpers.pluralize(like.likeable.likes.count, "like"),
      url: like_path(like, format: :json)
    }
  end

  def unable_to_unlike(like)
    respond_to do |format|
      format.html do
        flash[:error] = 'Unable to unlike'
        if like.likeable
          redirect_to like.likeable
        else
          redirect_to root_path
        end
      end
    end
  end

  def unable_to_like(like)
    respond_to do |format|
      format.html do
        flash[:error] = 'Unable to like'
        if like.likeable
          redirect_to like.likeable
        else
          redirect_to root_path
        end
      end
    end
  end
end
