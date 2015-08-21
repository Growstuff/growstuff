#
# Handle signup or signin
# from various oauth providers
#
# Heavily overlaps with Authentications controller
#
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    create
  end
  def failure
    flash[:error] = "Authentication failed."
    redirect_to request.env['omniauth.origin'] || "/"
  end

  private

  #
  # Inspects the omniauth information
  # and determines if we have an existing member 
  # (to add authentication to)
  # or if this is a new signup
  #
  # As a side affect, this method sets the @member_created
  # variable
  #
  def member
    @member_created = false

    auth = request.env['omniauth.auth']

    authentication = Authentication.where(provider: auth.provider, uid: auth.uid).first
    if authentication && authentication.member.id.present?
      member = authentication.member
    end

    member = Member.where(email: auth.info.email).first_or_create do |m|
      m.email = auth.info.email
      m.password = Devise.friendly_token[0,20]
      m.tos_agreement = true
      # TODO This has a reasonable chance of collision
      m.login_name = auth.info.nickname || auth.info.email.split("@").first.gsub(/[^A-Za-z]+/, '_').underscore

      m.skip_confirmation!

      # TODO Assess this later, if we introduce separate modelling for user photos
      # m.image = auth.info.image # assuming the user model has an image

      @member_created = true
    end
    member.save!
    
    member
  end

  def create
    auth = request.env['omniauth.auth']
    @authentication = nil
    if auth

      name = ''
      case auth['provider']
      when 'twitter'
        name = auth['info']['nickname']
      when 'flickr', 'facebook'
        name = auth['info']['name']
      else
        name = auth['info']['name']
      end

      @authentication = member.authentications
      .create_with(
        :name => name,
        :token => auth['credentials']['token'],
        :secret => auth['credentials']['secret'],
      )
      .find_or_create_by(
        :provider => auth['provider'],
        :uid => auth['uid'],
        :name => name,
        :member_id => member.id
      )

      unless @member_created
        sign_in_and_redirect member, :event => :authentication #this will throw if @user is not activated
        set_flash_message(:notice, :success, :kind => auth['provider']) if is_navigational_format?
      else
        session["devise.#{auth['provider']}_data"] = request.env["omniauth.auth"]
        redirect_to new_member_registration_url
      end
    else
      redirect_to request.env['omniauth.origin'] || edit_member_registration_path
    end
  end
end