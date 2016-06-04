class PostsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /posts
  # GET /posts.json

  def index
    @author = Member.find_by_slug(params[:author])
    if @author
      @posts = @author.posts.includes(:author, { comments: :author }).paginate(page: params[:page])
    else
      @posts = Post.includes(:author, { comments: :author }).paginate(page: params[:page])
    end

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @posts }
      format.rss { render layout: false } #index.rss.builder
    end
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    @post = Post.includes(:author, { comments: :author }).find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @post }
      format.rss { render(
        layout: false,
        locals: { post: @post }
      )}
    end
  end

  # GET /posts/new
  # GET /posts/new.json
  def new
    @post = Post.new
    @forum = Forum.find_by_id(params[:forum_id])

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @post }
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
  end

  # POST /posts
  # POST /posts.json
  def create
    params[:post][:author_id] = current_member.id
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render json: @post, status: :created, location: @post }
      else
        format.html { render action: "new" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.json
  def update
    @post = Post.find(params[:id])

    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def post_params
    params.require(:post).permit(:body, :subject, :author_id, :forum_id)
  end
end
