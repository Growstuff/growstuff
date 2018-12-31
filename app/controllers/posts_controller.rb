class PostsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :rss, only: %i(index show)

  responders :flash

  def index
    @author = Member.find_by(slug: params[:author])
    @posts = @posts.where author: @author if @author.present?
    @posts = @posts.order(created_at: :desc).includes(:author, comments: :author).paginate(page: params[:page])
    respond_with(@posts)
  end

  def show
    respond_with(@post)
  end

  def new
    @forum = Forum.find(params[:forum_id])
    respond_with(@post)
  end

  def edit; end

  def create
    @post = Post.new(post_params)
    @post.author = current_member
    @post.save
    respond_with(@post)
  end

  def update
    @post.update(post_params)
    respond_with(@post)
  end

  def destroy
    @post.destroy
    respond_with(@post)
  end

  private

  def post_params
    params.require(:post).permit(:body, :subject, :author_id, :forum_id)
  end
end
