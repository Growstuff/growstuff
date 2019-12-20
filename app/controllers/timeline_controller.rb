# frozen_string_literal: true

class TimelineController < ApplicationController
  def index
    if current_member
      @timeline = TimelineService.followed_query(current_member).paginate(page: params[:page])
      @members = current_member.followed
    else
      @timeline = TimelineService.query.paginate(page: params[:page])
      @members = Member.interesting.limit 10
    end
  end
end
