class Api::V1::PostsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /posts.json
  api!
  api :GET, '/posts/author/:author'
  def index
    @author = Member.find_by_slug(params[:author])
    if @author
      @posts = @author.posts.includes(:author, { comments: :author }).paginate(page: params[:page])
    else
      @posts = Post.includes(:author, { comments: :author }).paginate(page: params[:page])
    end

    respond_to do |format|
      format.json { render json: @posts }
    end
  end

  # GET /posts/1.json
  api!
  def show
    @post = Post.includes(:author, { comments: :author }).find(params[:id])

    respond_to do |format|
      format.json { render json: @post }
    end
  end

  # POST /posts.json
  api!
  def create
    params[:post][:author_id] = current_member.id
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.json { render json: @post, status: :created, location: @post }
      else
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1.json
  api!
  def update
    @post = Post.find(params[:id])

    respond_to do |format|
      if @post.update(post_params)
        format.json { head :no_content }
      else
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1.json
  api!
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def post_params
    params.require(:post).permit(:body, :subject, :author_id, :forum_id)
  end
end
