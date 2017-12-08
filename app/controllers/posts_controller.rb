class PostsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :rss, only: %i(index show)

  # GET /posts
  # GET /posts.json
  # GET /posts.rss
  def index
    @author = Member.find_by(slug: params[:author])
    @posts = posts
    respond_with(@posts)
  end

  # GET /posts/1
  # GET /posts/1.json
  # GET /posts/1.rss
  def show
    @post = Post.includes(:author, comments: :author).find(params[:id])
    respond_with(@post)
  end

  # GET /posts/new
  # GET /posts/new.json
  def new
    @post = Post.new
    @forum = Forum.find_by(id: params[:forum_id])
    respond_with(@post)
  end

  # GET /posts/1/edit
  def edit; end

  # POST /posts
  # POST /posts.json
  def create
    params[:post][:author_id] = current_member.id
    @post = Post.new(post_params)
    flash[:notice] = 'Post was successfully created.' if @post.save
    respond_with(@post)
  end

  # PUT /posts/1
  # PUT /posts/1.json
  def update
    flash[:notice] = 'Post was successfully updated.' if @post.update(post_params)
    respond_with(@post)
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    flash[:notice] = 'Post was deleted.' if @post.destroy
    respond_with(@post)
  end

  private

  def post_params
    params.require(:post).permit(:body, :subject, :author_id, :forum_id)
  end

  def posts
    if @author
      @author.posts
    else
      Post
    end.order(created_at: :desc).includes(:author, comments: :author).paginate(page: params[:page])
  end
end
