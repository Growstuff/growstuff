# frozen_string_literal: true

require 'ipaddr'
require 'resolv'

#
# Works out which OAuth client id and secret to use for a given Mastodon server.
#
# Unlike Flickr, there is no single Mastodon to register with: each server issues its
# own credentials. So the first time someone from a server connects, we register
# Growstuff there (POST /api/v1/apps, which needs no login) and keep what we are given.
#
# This is what the `credentials:` option of omniauth-mastodon calls, with the domain
# from the address the member typed in.
#
class MastodonClientService
  class Error < StandardError; end

  # What we ask each server for, and what the login asks each member for. They have to match.
  SCOPES = OmniAuth::Strategies::GrowstuffMastodon::SCOPE

  # A hostname with at least one dot, ending in a letter-led label. That rules out
  # IP addresses, ports, paths, and user@ prefixes before anything is looked up.
  DOMAIN_FORMAT = /\A(?=.{4,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])\z/

  # Addresses a public server never lives on. The real protection is that we only talk
  # https and check the certificate; this stops us even trying to reach our own network.
  BLOCKED_RANGES = %w(
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
    192.0.0.0/24 192.168.0.0/16 198.18.0.0/15 224.0.0.0/4 240.0.0.0/4
    ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8
  ).map { |range| IPAddr.new(range) }.freeze

  def initialize(resolver: Resolv, adapter: Faraday.default_adapter)
    @resolver = resolver
    @adapter = Array(adapter)
  end

  # @return [Array<String>] the client id and client secret for this server
  def credentials_for(domain, callback_url)
    domain = normalise(domain)
    client = MastodonClient.find_by(domain:)
    client = register(domain, callback_url) unless usable?(client, callback_url)

    [client.client_id, client.client_secret]
  end

  private

  # The server only accepts the callback URL we registered, so a client made for a
  # different one (say the site moved) has to be registered again.
  def usable?(client, callback_url)
    client.present? && client.redirect_uri == callback_url && secret_readable?(client)
  end

  # If the encryption keys have changed since we stored it, the secret can't be read back.
  def secret_readable?(client)
    client.client_secret.present?
  rescue ActiveRecord::Encryption::Errors::Base
    false
  end

  def normalise(domain)
    domain = domain.to_s.strip.downcase
    raise Error, "#{domain.inspect} is not a server name" unless DOMAIN_FORMAT.match?(domain)

    domain
  end

  def register(domain, callback_url)
    ensure_public_host!(domain)
    registration = request_registration(domain, callback_url)

    replace_client(domain, callback_url, registration)
  rescue ActiveRecord::RecordNotUnique
    # Two members from a new server connected at once; use whichever registration won.
    MastodonClient.find_by!(domain:)
  end

  # Replaced, not updated: an old row whose secret can't be decrypted can't be updated.
  def replace_client(domain, callback_url, registration)
    MastodonClient.transaction do
      MastodonClient.where(domain:).delete_all
      MastodonClient.create!(domain:,
                             client_id:     registration['client_id'],
                             client_secret: registration['client_secret'],
                             redirect_uri:  callback_url)
    end
  end

  def request_registration(domain, callback_url)
    response = connection(domain).post('/api/v1/apps') do |request|
      request.body = {
        client_name:   ENV.fetch('GROWSTUFF_SITE_NAME', 'Growstuff'),
        redirect_uris: callback_url,
        scopes:        SCOPES,
        website:       URI.join(callback_url, '/').to_s
      }
    end
    raise Error, "#{domain} would not let us register (HTTP #{response.status})" unless response.success?

    parse_registration(domain, response.body)
  rescue Faraday::Error => e
    raise Error, "Could not reach #{domain} (#{e.class})"
  end

  def parse_registration(domain, body)
    data = JSON.parse(body)
    complete = data.is_a?(Hash) && data.values_at('client_id', 'client_secret').all?(&:present?)
    raise Error, "#{domain} gave an unexpected answer" unless complete

    data
  rescue JSON::ParserError
    raise Error, "#{domain} gave an unexpected answer"
  end

  def connection(domain)
    Faraday.new(url: "https://#{domain}") do |faraday|
      faraday.request :url_encoded
      faraday.options.open_timeout = 5
      faraday.options.timeout = 10
      faraday.adapter(*@adapter)
    end
  end

  def ensure_public_host!(domain)
    addresses = @resolver.getaddresses(domain).map { |address| IPAddr.new(address) }
    raise Error, "#{domain} does not exist" if addresses.empty?
    raise Error, "#{domain} is not a public server" if addresses.any? { |address| blocked?(address) }
  rescue IPAddr::Error
    raise Error, "#{domain} is not a public server"
  end

  def blocked?(address)
    address = address.native if address.ipv4_mapped?
    BLOCKED_RANGES.any? { |range| range.family == address.family && range.include?(address) }
  end
end
