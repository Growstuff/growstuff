class LikesController < ApplicationController
  before_action :authenticate_member!
  respond_to :html, :json

  def create
    @like = Like.new(member: current_member, likeable: find_likeable)
    unable_to_like(@like.likeable) unless @like.likeable && @like.save

    respond_to do |format|
      format.html { redirect_to @like.likeable }
      format.json { render(json: render_json(@like), status: 201) }
    end
  end

  def destroy
    like = Like.find(params[:id])
    likeable = like.likeable
    respond_to do |format|
      if like.destroy
        format.html { redirect_to likeable }
        format.json do
          render(
            json: {
              id: likeable.id,
              liked_by_member: false,
              description: ActionController::Base.helpers.pluralize(likeable.likes.count, "like"),
              url: likes_path(Like.new, "#{likeable.class.name.underscore}_id", likeable.id, format: :json)
            },
            status: 200
          )
        end
      else
        format.html do
          flash[:error] = 'Unable to unlike'
          redirect_to likeable
        end
      end
    end
  end

  private

  def find_likeable
    # params.each do |name, value|
    #   return Regexp.last_match[1].classify.constantize.find(value) if name =~ /(.+)_id$/
    # end
    Post.find(params[:post_id]) if params[:post_id]
  end

  def like_params
    params.require(:like).permit(:post_id)
  end

  def render_json(like)
    {
      id: like.likeable.id,
      liked_by_member: true,
      description: ActionController::Base.helpers.pluralize(like.likeable.likes.count, "like"),
      url: like_path(like, format: :json)
    }
  end

  def unable_to_like(likeable)
    respond_to do |format|
      format.html do
        flash[:error] = 'Unable to like'
        if likeable
          redirect_to @like.likeable
        else
          redirect_to root_path
        end
      end
    end
  end
end
