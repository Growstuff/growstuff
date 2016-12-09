class LikesController < ApplicationController
  before_action :authenticate_member!, :except => :index
 
  respond_to :html, :json

  def create
    @like = Like.new
    @like.member = current_member
    @like.likeable = find_likeable

    respond_to do |format|
      if @like.save
        format.html { redirect_to @like.likeable }
        format.json { 
          render({
            json: {
              id: @like.likeable.id,
              liked_by_member: true,
              description: ActionController::Base.helpers.pluralize(@like.likeable.likes.count, "like"),
              url: like_path(@like, format: :json)
            }, 
            status: 201
          })
        }
      else
        format.html do 
          flash[:error] = 'Unable to like'
          redirect_to @like.likeable
        end
      end
    end
  end

  def destroy
    like = Like.find(params[:id])
    likeable = like.likeable
    respond_to do |format|
      if like.destroy
        format.html { redirect_to likeable }
        format.json {
          render({
            json: {
              id: likeable.id,
              liked_by_member: false,
              description: ActionController::Base.helpers.pluralize(likeable.likes.count, "like"),
              url: likes_path(Like.new, "#{likeable.class.name.underscore}_id", likeable.id, format: :json)
            }, 
            status: 200
          })
        }
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
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value)
      end
    end
  end

  def like_params
    params.require(:like).permit(:member, :likeable)
  end

end
