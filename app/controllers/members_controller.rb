class MembersController < ApplicationController
  load_and_authorize_resource except: %i(finish_signup unsubscribe view_follows view_followers show)
  skip_authorize_resource only: %i(nearby unsubscribe finish_signup)
  respond_to :html, :json, :rss

  def index
    @sort = params[:sort]
    @members = members
    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members.to_json(only: member_json_fields) }
    end
  end

  # Queries for the show view/action
  def plantings_for_show
    Planting.select(
      :id,
      "'planting' as event_type",
      'planted_at as event_at',
      :owner_id,
      :crop_id,
      :slug
    )
  end

  def harvests_for_show
    Harvest.select(
      :id,
      "'harvest' as event_type",
      'harvested_at as event_at',
      :owner_id,
      :crop_id,
      :slug
    )
  end

  def posts_for_show
    Post.select(
      :id,
      "'post' as event_type",
      'posts.created_at as event_at',
      'author_id as owner_id',
      'null as crop_id',
      :slug
    )
  end

  def comments_for_show
    Comment.select(
      :id,
      "'comment' as event_type",
      'comments.created_at as event_at',
      'author_id as owner_id',
      'null as crop_id',
      'null as slug'
    )
  end

  def photos_for_show
    Photo.select(
      :id,
      "'photo' as event_type",
      "photos.created_at as event_at",
      'photos.owner_id',
      'null as crop_id',
      'null as slug'
    )
  end

  def show
    @member        = Member.confirmed.find_by!(slug: params[:slug])
    @twitter_auth  = @member.auth('twitter')
    @flickr_auth   = @member.auth('flickr')
    @facebook_auth = @member.auth('facebook')
    @posts         = @member.posts

    # TODO: Consider shifting all of these onto a member activity model?
    @activity = plantings_for_show
      .union_all(harvests_for_show)
      .union_all(posts_for_show)
      .union_all(comments_for_show)
      .union_all(photos_for_show)
      .where(owner_id: @member.id)
      .order(event_at: :desc)
      .limit(30)

    # The garden form partial is called from the "New Garden" tab;
    # it requires a garden to be passed in @garden.
    # The new garden is not persisted unless Garden#save is called.
    @garden = Garden.new

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @member.to_json(only: member_json_fields) }
      format.rss do
        render(
          layout: false,
          locals: { member: @member }
        )
      end
    end
  end

  EMAIL_TYPE_STRING = {
    send_notification_email: "direct message notifications",
    send_planting_reminder:  "planting reminders"
  }.freeze

  def unsubscribe
    verifier = ActiveSupport::MessageVerifier.new(ENV['RAILS_SECRET_TOKEN'])
    decrypted_message = verifier.verify(params[:message])

    @member = Member.find(decrypted_message[:member_id])
    @type = decrypted_message[:type]
    @member.update(@type => false)

    flash.now[:notice] = I18n.t('members.unsubscribed', email_type: EMAIL_TYPE_STRING[@type])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    flash.now[:alert] = I18n.t('members.unsubscribe.error')
  end

  def finish_signup
    @member = current_member
    return unless request.patch? && params[:member]

    if @member.update(member_params)
      @member.skip_reconfirmation!
      bypass_sign_in(@member)
      redirect_to root_path, notice: I18n.t('members.welcome')
    else
      flash[:alert] = I18n.t('members.signup.error')
      @show_errors = true
    end
  end

  private

  def member_params
    params.require(:member).permit(:login_name, :tos_agreement, :email, :newsletter)
  end

  def member_json_fields
    %i(
      id login_name
      slug bio created_at
      location latitude longitude
    )
  end

  def members
    if @sort == 'recently_joined'
      Member.recently_joined
    else
      Member.order(:login_name)
    end.confirmed.paginate(page: params[:page])
  end
end
