class MembersController < ApplicationController
  load_and_authorize_resource except: %i(finish_signup unsubscribe view_follows view_followers show)
  skip_authorize_resource only: %i(nearby unsubscribe finish_signup)
  respond_to :html, :json, :rss
  after_action :expire_homepage, only: :create

  def index
    @sort = params[:sort]
    @members = members
    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @members.to_json(only: member_json_fields) }
    end
  end

  def show
    @member        = Member.confirmed.find(params[:id])
    @twitter_auth  = @member.auth('twitter')
    @flickr_auth   = @member.auth('flickr')
    @facebook_auth = @member.auth('facebook')
    @posts         = @member.posts
    @gardens       = @member.gardens.active.order(:name)

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

  def view_follows
    @member = Member.confirmed.find(params[:login_name])
    @follows = @member.followed.paginate(page: params[:page])
  end

  def view_followers
    @member = Member.confirmed.find(params[:login_name])
    @followers = @member.followers.paginate(page: params[:page])
  end

  EMAIL_TYPE_STRING = {
    send_notification_email: "direct message notifications",
    send_planting_reminder: "planting reminders"
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
