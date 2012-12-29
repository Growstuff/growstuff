class MembersController < ApplicationController
  def index
    @members = User.confirmed

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members}
    end
  end

  def show
    @member = User.confirmed.find(params[:id])
    @updates = @member.updates
    # The garden form partial is called from the "New Garden" tab;
    # it requires a garden to be passed in @garden.
    # The new garden is not persisted unless Garden#save is called.
    @garden = Garden.new

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
