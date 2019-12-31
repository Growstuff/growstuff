# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :authenticate_member!
  respond_to :html, :json

  def create
    @like = Like.new(
      member:        current_member,
      likeable_type: params[:type],
      likeable_id:   params[:id]
    )
    if @like.likeable && @like.save
      @like.likeable.reindex(refresh: true)
      success(@like, liked_by_member: true, status_code: :created)
    else
      failed(@like, message: 'Unable to like')
    end
  end

  def destroy
    @like = Like.find_by(
      likeable_type: params[:type],
      likeable_id:   params[:id],
      member:        current_member
    )

    if @like&.destroy
      @like.likeable.reindex(refresh: true)
      success(@like, liked_by_member: false, status_code: :ok)
    else
      failed(@like, message: 'Unable to unlike')
    end
  end

  private

  def render_json(like, liked_by_member: true)
    {
      id:              like.likeable.id,
      like_count:      like.likeable.likes.count,
      liked_by_member: liked_by_member,
      description:     ActionController::Base.helpers.pluralize(like.likeable.likes.count, "like")
    }
  end

  def success(like, liked_by_member: nil, status_code: nil)
    respond_to do |format|
      format.html { redirect_to like.likeable }
      format.json do
        render(json: render_json(
          like,
          liked_by_member: liked_by_member
        ), status: status_code)
      end
    end
  end

  def failed(like, message)
    respond_to do |format|
      format.json { render(json: { 'error': message }, status: :forbidden) }
      format.html do
        flash[:error] = message
        if like&.likeable
          redirect_to like.likeable
        else
          redirect_to root_path
        end
      end
    end
  end
end
