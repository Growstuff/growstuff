# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  before_action :find_post, only: %i(show edit update destroy)
  load_and_authorize_resource except: %i(preview link_suggestions)
  responders :flash
  respond_to :html, :json
  respond_to :rss, only: %i(index show)

  def index
    @author = Member.find_by!(slug: params[:member_slug]) if params[:member_slug].present?
    @posts = posts
    respond_with(@posts)
  end

  def show
    respond_with(@post)
  end

  def new
    @post = Post.new
    @forum = Forum.find_by(id: params[:forum_id])
    if params[:crop_id]
      @crop = Crop.friendly.find(params[:crop_id])
      @post.body = "[#{@crop.name}](crop)"
    end
    respond_with(@post)
  end

  def edit; end

  # What the editor's "link to" list offers besides crops (which it gets from
  # /crops/search.json): members, and the plantings of the member writing.
  def link_suggestions
    authorize! :create, Post
    term = params[:term].to_s.strip
    render json: { members: member_suggestions(term), plantings: planting_suggestions(term) }
  end

  # The body as it will look when posted, for the editor's Preview tab.
  def preview
    authorize! :create, Post
    render partial: 'posts/body', formats: [:html], locals: { body: params[:body].to_s }
  end

  def create
    params[:post][:author_id] = current_member.id
    @post = Post.new(post_params)
    flash[:notice] = t(@post.draft? ? 'posts.draft_saved' : 'posts.created') if @post.save
    respond_with(@post)
  end

  def update
    was_draft = @post.draft?
    if @post.update(post_params)
      flash[:notice] = t(was_draft && @post.published? ? 'posts.created' : 'posts.updated')
    end
    respond_with(@post)
  end

  def destroy
    flash[:notice] = t('posts.deleted') if @post.destroy
    respond_with(@post)
  end

  private

  SUGGESTIONS = 5

  def member_suggestions(term)
    return [] if term.blank?

    Member.kept.confirmed.where('login_name ILIKE ?', "#{Member.sanitize_sql_like(term)}%")
          .order(:login_name).limit(SUGGESTIONS).map { |member| { name: member.login_name } }
  end

  def planting_suggestions(term)
    return [] if term.blank?

    like = "#{Planting.sanitize_sql_like(term)}%"
    current_member.plantings.joins(:crop, :garden).includes(:crop, :garden)
                  .where('crops.name ILIKE :like OR gardens.name ILIKE :like', like:)
                  .order(created_at: :desc).limit(SUGGESTIONS)
                  .map { |planting| { slug: planting.slug, name: planting.to_s, crop: planting.crop.name } }
  end

  # A draft is only its author's: to anyone else it does not exist.
  def find_post
    @post = Post.with_drafts.includes(:author).find(params[:id])
    raise ActiveRecord::RecordNotFound if @post.draft? && @post.author != current_member
  end

  def post_params
    params.require(:post).permit(:body, :subject, :author_id, :forum_id, :card_photo_id, :draft)
  end

  # All of their own posts with drafts among them, or only the drafts.
  def own_posts
    return @author.posts unless @author == current_member

    mine = Post.with_drafts.where(author: @author)
    params[:drafts].present? ? mine.where(published_at: nil) : mine
  end

  def posts
    if @author
      # Members see their own drafts on their own page.
      own_posts
    else
      Post
    end.order(created_at: :desc)
      .includes(:author,  :crop_posts, :crops, comments: :author)
      .paginate(page: params[:page], per_page: 12)
  end
end
