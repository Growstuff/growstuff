class MembersController < ApplicationController
  load_and_authorize_resource
  def index
    @members = Member.confirmed.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.haml
    end
  end

  def show
    @member = Member.confirmed.find(params[:id])
    @posts = @member.posts
    # The garden form partial is called from the "New Garden" tab;
    # it requires a garden to be passed in @garden.
    # The new garden is not persisted unless Garden#save is called.
    @garden = Garden.new

    respond_to do |format|
      format.html # show.html.haml
      format.rss { render(
        :layout => false,
        :locals => { :member => @member }
      )}
    end
  end

  def nearby
    if !params[:location].blank?
      @location = params[:location]
    elsif current_member
      @location = current_member.location
    else
      @location = nil
    end
    @distance = 100
    @nearby_members = @location ? Member.near(@location, @distance) : []
    respond_to do |format|
      format.html # nearby.html.haml
      format.json { render json: @nearby_members }
    end
  end

end
