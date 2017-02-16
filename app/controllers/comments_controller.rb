class CommentsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :rss, only: :index

  # GET /comments
  # GET /comments.json
  # GET /comments.rss
  def index
    @comments = Comment.paginate(page: params[:page])
    respond_with(@comments)
  end

  # GET /comments/new
  # GET /comments/new.json
  def new
    @comment = Comment.new
    @post = Post.find_by(id: params[:post_id])

    if @post
      @comments = @post.comments
      respond_with(@comment)
    else
      redirect_to(request.referer || root_url,
        alert: "Can't post a comment on a non-existent post")
    end
  end

  # GET /comments/1/edit
  def edit
    @comments = @comment.post.comments
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params)
    @comment.author = current_member
    flash[:notice] = "Comment was successfully created." if @comment.save
    respond_with(@comment.post)
  end

  # PUT /comments/1
  # PUT /comments/1.json
  def update
    # only body can be updated
    if @comment.update(body: comment_params['body'])
      flash[:notice] = 'Comment was successfully updated.'
    end
    respond_with(@comment.post)
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
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
