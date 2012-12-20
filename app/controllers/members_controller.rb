class MembersController < ApplicationController
  def index
    @members = User.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members}
    end
  end

  def show
    @member = User.find(params[:id])
    @updates = @member.updates
    @garden = Garden.new # in case a new garden is created; not persisted yet

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @member }
      format.rss { render(
        :layout => false,
        :locals => { :member => @member }
      )}
    end
  end

end
