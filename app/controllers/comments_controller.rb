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
    @comment = Comment.new
    if @commentable
      @comments = @commentable.comments
      respond_with(@comments)
    else
      redirect_to(request.referer || root_url,
                  alert: "Can't post a comment on a non-existent commentable")
    end
  end

  def edit
    # TODO: Why does this need a collection of comments?
    @comments = @comment.commentable.comments
    @commentable = @comment.commentable
  end

  def create
    @comment = Comment.new(comment_params)
    @commentable = @comment.commentable
    @comment.author = current_member
    @comment.save
    respond_with @comment, location: @commentable
  end

  def update
    @comment.update(body: comment_params['body'])
    respond_with @comment, location: @comment.commentable
  end

  def destroy
    @commentable = @comment.commentable
    @comment.destroy
    respond_with(@commentable)
  end

  private

  def find_commentable
    return unless params[:comment]

    if params[:comment][:commentable_type] == 'Photo'
      Photo.find(params[:comment][:commentable_id])
    elsif params[:comment][:commentable_type] == 'Post'
      Post.find(params[:comment][:commentable_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body, :commentable_id, :commentable_type)
  end
end
