class MembersController < ApplicationController
  def index
    @members = User.confirmed

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members}
    end
  end

  def show
    @member = User.find_confirmed(params[:id])
    @updates = @member.updates

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
