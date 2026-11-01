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
  def find_or_create_from_authorization(auth, tos_agreement: nil)
    member = existing_member(auth) || build_member(auth, tos_agreement:)
    member.save!

    member
  end

  def existing_member(auth)
    by_authentication = Authentication.where(provider: auth.provider, uid: uid_for(auth)).select(:member_id)
    # Never match on a blank email: that would hand someone else's account to anyone without one.
    Member.kept.find_by(id: by_authentication) ||
      (Member.kept.find_by(email: auth.info.email) if auth.info.email.present?)
  end

  def build_member(auth, tos_agreement: nil)
    Member.new do |m|
      m.tos_agreement = tos_agreement
      m.settings = m.settings.merge('username' => 'unconfirmed') # they confirm it on the home page
      m.email = auth.info.email.presence
      m.email_optional = m.email.blank? && Authentication::EMAIL_OPTIONAL_PROVIDERS.include?(auth.provider)
      m.password = Devise.friendly_token[0, 20]

      m.login_name = available_login_name(auth)
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
        token:  (auth.dig('credentials', 'token') unless auth['provider'] == 'mastodon'),
        secret: (auth.dig('credentials', 'secret') unless auth['provider'] == 'mastodon')
      )
      .find_or_create_by(
        provider:  auth['provider'],
        uid:       uid_for(auth),
        member_id: member.id
      )
    authentication.update(name:) if authentication.persisted? && authentication.name != name
    authentication
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

  # The shortest name that is free. From a nickname such as a Bluesky handle,
  # alice.bsky.social, that is alice; only if it is taken do we add more of the
  # handle (alice_bsky, then alice_bsky_social). With none free, a random name
  # so the member can choose their own.
  def available_login_name(auth)
    login_name_candidates(auth).find { |name| login_name_free?(name) } || Devise.friendly_token[0, 20]
  end

  # Names that pass Member's validation, shortest first: the parts of a nickname
  # (or an email's local part) before each dot, joined up.
  def login_name_candidates(auth)
    parts = (auth.info.nickname.presence || auth.info.email.to_s.split("@").first).to_s.split('.')
    (1..parts.size).map { |count| parts.first(count).join('_').gsub(/[^A-Za-z0-9]+/, '_').first(25) }.select { |name| name.length >= 2 }
  end

  def login_name_free?(name)
    Member.where('lower(login_name) = ?', name.downcase).none? && Member::RESERVED_LOGIN_NAMES.exclude?(name.downcase)
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
