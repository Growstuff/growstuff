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
    member ||= Member.where(email: auth.info.email).first_or_create do |m|
      m.email = auth.info.email
      m.password = Devise.friendly_token[0, 20]

      # First, try the nickname or friendly generate from the email
      m.login_name = auth.info.nickname || auth.info.email.split("@").first.gsub(/[^A-Za-z]+/, '_').underscore

      # Do we have a collision with an existing account? Generate a 20 character long random name
      # so the user can update it later
      m.login_name = Devise.friendly_token[0, 20] if Member.where(login_name: m.login_name).any?
      m.preferred_avatar_uri = auth.info.image # assuming the user model has an image
      m.skip_confirmation!

      @member_created = true
    end

    member.save!

    member
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
        name:   name,
        token:  auth['credentials']['token'],
        secret: auth['credentials']['secret']
      )
      .find_or_create_by(
        provider:  auth['provider'],
        uid:       auth['uid'],
        name:      name,
        member_id: member.id
      )

    authentication
  end

  def member_created?
    @member_created
  end

  def determine_name(auth)
    name = ''
    case auth['provider']
    when 'twitter'
      name = auth['info']['nickname']
    when 'flickr', 'facebook'
      name = auth['info']['name']
    else
      name = auth['info']['name']
    end

    name
  end
end
