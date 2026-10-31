# frozen_string_literal: true

class Growstuff::OauthSignupAction
  #
  # Inspects the omniauth information
  # and determines if we have an existing member
  # (to add authentication to)
  # or if this is a new signup
  #
  # As a side affect, this method sets the @member_created
  # variable
  #
  def find_or_create_from_authorization(auth)
    member = existing_member(auth) || build_member(auth)
    member.save!

    member
  end

  def existing_member(auth)
    by_authentication = Authentication.where(provider: auth.provider, uid: auth.uid).select(:member_id)
    # Never match on a blank email: that would hand someone else's account to anyone without one.
    Member.kept.find_by(id: by_authentication) ||
      (Member.kept.find_by(email: auth.info.email) if auth.info.email.present?)
  end

  def build_member(auth)
    Member.new do |m|
      m.email = auth.info.email.presence
      m.email_optional = m.email.blank? && Authentication::EMAIL_OPTIONAL_PROVIDERS.include?(auth.provider)
      m.password = Devise.friendly_token[0, 20]

      # First, try the nickname or friendly generate from the email
      m.login_name = login_name_from(auth)

      # Do we have a collision with an existing account? Generate a 20 character long random name
      # so the user can update it later
      m.login_name = Devise.friendly_token[0, 20] if Member.where(login_name: m.login_name).any?
      m.preferred_avatar_uri = auth.info.image # assuming the user model has an image
      m.bluesky_handle = auth.info.handle if auth.provider == 'bluesky'
      m.skip_confirmation!

      @member_created = true
    end
  end

  #
  # For a given auth hash (from omniauth), and a specified member
  # See if:
  # - The member already has this authentication or
  # - We need to create it
  #
  def establish_authentication(auth, member)
    name = determine_name(auth)

    authentication = member.authentications
      .create_with(
        name:,
        token:  auth['credentials']['token'],
        secret: auth['credentials']['secret']
      )
      .find_or_create_by(
        provider:  auth['provider'],
        uid:       auth['uid'],
        member_id: member.id
      )
    authentication.update(name:) if authentication.persisted? && authentication.name != name
    authentication
  end

  def member_created?
    @member_created
  end

  # A login name that passes Member's validation: handles like alice.bsky.social
  # have dots, and an email's local part can have anything.
  def login_name_from(auth)
    name = (auth.info.nickname.presence || auth.info.email.to_s.split("@").first).to_s.gsub(/[^A-Za-z0-9]+/, '_')
    name.first(25).presence || Devise.friendly_token[0, 20]
  end

  def determine_name(auth)
    case auth['provider']
    when 'flickr'
      auth['info']['name']
    else
      auth['info']['name']
    end
  end
end
