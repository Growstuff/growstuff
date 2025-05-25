# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_member!, except: %i(index)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :rss, only: :index
  responders :flash

  def index
    @comments = Comment.order(created_at: :desc).paginate(page: params[:page])
    respond_with(@comments)
  end

  def new
    @commentable = find_commentable
    if @commentable
      @comment = @commentable.comments.new
      @comments = @commentable.comments.post_order # Assuming post_order is generic enough or will be adapted
      respond_with(@comment) # Changed from @comments to @comment, or @commentable
    else
      redirect_to(request.referer || root_url,
                  alert: "Cannot add a comment to a non-existent or unspecified item.")
    end
  end

  def edit
    # @comment is loaded by load_and_authorize_resource
    @comments = @comment.commentable.comments.post_order # Assuming post_order is generic
  end

  def create
    @commentable = find_commentable
    if @commentable
      @comment = @commentable.comments.new(comment_params)
      @comment.author = current_member
      @comment.save
      respond_with @comment, location: @comment.commentable # Redirect to the commentable parent
    else
      redirect_to(request.referer || root_url,
                  alert: "Cannot create comment for a non-existent or unspecified item.")
    end
  end

  def update
    # @comment is loaded by load_and_authorize_resource
    @comment.update(comment_params) # body is permitted by comment_params
    respond_with @comment, location: @comment.commentable # Redirect to the commentable parent
  end

  def destroy
    # @comment is loaded by load_and_authorize_resource
    @commentable = @comment.commentable # Store before destroying
    @comment.destroy
    respond_with @comment, location: @commentable # Redirect to the commentable parent
  end

  private

  def find_commentable
    params.each do |name, value|
      if name =~ /(.+)_id$/
        model_name = $1.classify
        # Ensure model_name is one of the expected commentable types
        # to prevent arbitrary model lookups.
        allowed_commentables = %w[Post Photo Planting Harvest Activity]
        if allowed_commentables.include?(model_name)
          return model_name.constantize.find_by(id: value)
        end
      end
    end
    nil
  end

  def comment_params
    params.require(:comment).permit(:body) # Removed post_id
  end
end
