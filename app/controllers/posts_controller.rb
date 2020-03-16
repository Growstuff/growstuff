# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  responders :flash
  respond_to :html, :json
  respond_to :rss, only: %i(index show)

  def index
    @author = Member.find_by(slug: params[:member_slug])
    @posts = posts
    respond_with(@posts)
  end

  def show
    @post = Post.includes(:author, comments: :author).find(params[:id])
    respond_with(@post)
  end

  def new
    @post = Post.new
    @forum = Forum.find_by(id: params[:forum_id])
    respond_with(@post)
  end

  def edit; end

  def create
    params[:post][:author_id] = current_member.id
    @post = Post.new(post_params)
    flash[:notice] = 'Post was successfully created.' if @post.save
    respond_with(@post)
  end

  def update
    flash[:notice] = 'Post was successfully updated.' if @post.update(post_params)
    respond_with(@post)
  end

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
    end.order(created_at: :desc)
      .includes(:author,  :crop_posts, :crops, comments: :author)
      .paginate(page: params[:page], per_page: 12)
  end
end
