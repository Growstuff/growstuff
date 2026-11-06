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
  def find_or_create_from_authorization(auth, tos_agreement: nil)
    member = existing_member(auth) || build_member(auth, tos_agreement:)
    member.save!

    member
  end

  def existing_member(auth)
    by_authentication = Authentication.where(provider: auth.provider, uid: auth.uid).select(:member_id)
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
    else
      auth['info']['name']
    end
  end
end
