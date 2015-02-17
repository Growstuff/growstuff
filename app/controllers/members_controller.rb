class MembersController < ApplicationController
  load_and_authorize_resource

  skip_authorize_resource :only => :nearby

  after_action :expire_cache_fragments, :only => :create

  def index
    @sort = params[:sort]
    if @sort == 'recently_joined'
      @members = Member.confirmed.recently_joined.paginate(:page => params[:page])
    else
      @members = Member.confirmed.paginate(:page => params[:page])
    end

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
    @follows = @member.followed.paginate(:page => params[:page])
  end

  def view_followers
    @member = Member.confirmed.find(params[:login_name])
    @followers = @member.followers.paginate(:page => params[:page])
  end

  private

  def expire_cache_fragments
    expire_fragment("homepage_stats")
  end

end
