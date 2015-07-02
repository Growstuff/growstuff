class LikesController < ApplicationController
  before_filter :authenticate_member!, :except => :index

  def create
    @like = Like.new
    @like.member = current_member
    @like.likeable = find_likeable

    respond_to do |format|
      if @like.save
        format.html { redirect_to @like.likeable }
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
