class MembersController < ApplicationController
  def index
    @members = Member.confirmed

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members}
    end
  end

  def show
    @member = Member.find_confirmed(params[:id])
    @posts = @member.posts
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
