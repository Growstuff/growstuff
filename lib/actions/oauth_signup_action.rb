# frozen_string_literal: true

class Growstuff::OauthSignupAction
  class InvalidAuthorization < StandardError; end

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
    member ||= Member.kept.where(email: auth.info.email).first_or_create do |m|
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

    member.authentications
      .create_with(
        name:,
        token:  auth['credentials']['token'],
        secret: auth['credentials']['secret']
      )
      .find_or_create_by(
        provider:  auth['provider'],
        uid:       uid_for(auth),
        name:,
        member_id: member.id
      )
  end

  # What identifies this account to us.
  #
  # Mastodon's uid is a number that is only unique on one server: user 111 on one
  # server is not user 111 on another. So we add the server's domain.
  def uid_for(auth)
    return auth['uid'] unless auth['provider'] == 'mastodon'

    "#{auth['uid']}@#{mastodon_domain(auth)}"
  end

  def member_created?
    @member_created
  end

  def determine_name(auth)
    case auth['provider']
    when 'flickr'
      auth['info']['name']
    when 'mastodon'
      "@#{auth.dig('info', 'nickname') || auth.dig('info', 'name')}@#{mastodon_domain(auth)}"
    else
      auth['info']['name']
    end
  end

  private

  # The server the account lives on, from the address of its profile page.
  def mastodon_domain(auth)
    host = URI.parse(auth.dig('info', 'urls', 'Profile').to_s).host
    raise InvalidAuthorization, 'Mastodon did not say which server the account is on' if host.blank?

    host.downcase
  rescue URI::InvalidURIError
    raise InvalidAuthorization, 'Mastodon gave a profile address we could not read'
  end
end
