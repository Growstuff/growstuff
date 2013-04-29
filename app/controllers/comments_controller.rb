class CommentsController < ApplicationController
  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.all
    @recent_comments = Comment.limit(100).order('created_at desc').all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.json
  def new
    @comment = Comment.new
    @post = Post.find_by_id(params[:post_id])

    if @post
      @comments = @post.comments
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @comment }
      end
    else
      redirect_to request.referer || root_url,
        :alert => "Can't post a comment on a non-existent post"
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])
    @comments = @comment.post.comments
  end

  # POST /comments
  # POST /comments.json
  def create
    params[:comment][:author_id] = current_member.id
    @comment = Comment.new(params[:comment])

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @comment.post, notice: 'Comment was successfully created.' }
        format.json { render json: @comment, status: :created, location: @comment }
      else
        format.html { render action: "new" }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.json
  def update
    @comment = Comment.find(params[:id])

    # you should never be able to change the author or post when
    # updating
    params[:comment].delete("post_id")
    params[:comment].delete("author_id")

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to @comment.post, notice: 'Comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    @comment = Comment.find(params[:id])
    @post = @comment.post
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to @post }
      format.json { head :no_content }
    end
  end
end
