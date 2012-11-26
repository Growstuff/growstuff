class MembersController < ApplicationController
  def index
    @members = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @members}
    end
  end

  def show
    @member = User.find(params[:id])
    @updates = @member.updates

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @member }
      format.rss { render(
        :layout => false,
        :locals => { :member => @member }
      )}
    end
  end

end
