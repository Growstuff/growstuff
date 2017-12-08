class CommentsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :rss, only: :index
  responders :flash

  def index
    @comments = Comment.order(created_at: :desc).paginate(page: params[:page])
    respond_with(@comments)
  end

  def new
    @comment = Comment.new
    @post = Post.find_by(id: params[:post_id])

    if @post
      @comments = @post.comments
      respond_with(@comments)
    else
      redirect_to(request.referer || root_url,
        alert: "Can't post a comment on a non-existent post")
    end
  end

  def edit
    @comments = @comment.post.comments
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.author = current_member
    @comment.save
    respond_with @comment, location: @comment.post
  end

  def update
    @comment.update(body: comment_params['body'])
    respond_with @comment, location: @comment.post
  end

  def destroy
    @post = @comment.post
    @comment.destroy
    respond_with(@post)
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :post_id)
  end
end
