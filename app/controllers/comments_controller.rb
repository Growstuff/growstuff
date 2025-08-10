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
  end

  def edit
    @comments = @comment.commentable.comments
  end

  def create
    @commentable = find_commentable
    @comment = @commentable.comments.build(comment_params)
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
    if params[:comment]
      if params[:comment][:commentable_type] == 'Photo'
        Photo.find(params[:comment][:commentable_id])
      elsif params[:comment][:commentable_type] == 'Post'
        Post.find(params[:comment][:commentable_id])
      end
    elsif params[:post_id]
      Post.find(params[:post_id])
    elsif params[:photo_id]
      Photo.find(params[:photo_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body, :post_id, :commentable_id, :commentable_type)
  end
end
