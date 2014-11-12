class MembersController < ApplicationController
  load_and_authorize_resource

  cache_sweeper :member_sweeper

  skip_authorize_resource :only => :nearby

  def index
    @members = Member.confirmed.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.haml
      format.json { render :json => @members.to_json(:only => [:id, :login_name, :slug, :bio, :created_at, :location, :latitude, :longitude]) }
    end
  end

  def show
    @member       = Member.confirmed.find(params[:id])
    @twitter_auth = @member.auth('twitter')
    @flickr_auth  = @member.auth('flickr')
    @posts        = @member.posts
    # The garden form partial is called from the "New Garden" tab;
    # it requires a garden to be passed in @garden.
    # The new garden is not persisted unless Garden#save is called.
    @garden = Garden.new
    
    respond_to do |format|
      format.html # show.html.haml
      format.json { render :json => @member.to_json(:only => [:id, :login_name, :bio, :created_at, :slug, :location, :latitude, :longitude]) }
      format.rss { render(
        :layout => false,
        :locals => { :member => @member }
      )}
    end
  end

  def view_follows
    @member = Member.confirmed.find(params[:login_name])
    @follows = @member.followed
  end

  def view_followers
    @member = Member.confirmed.find(params[:login_name])
    @followers = @member.followers
  end

end
