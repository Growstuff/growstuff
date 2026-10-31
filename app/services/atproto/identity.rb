# frozen_string_literal: true

module Atproto
  # Turns a handle such as alice.bsky.social into a DID and the PDS that holds
  # their account, and checks the DID document agrees the handle is theirs.
  class Identity
    class Error < StandardError; end

    HANDLE_FORMAT = /\A([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]([a-z0-9-]{0,61}[a-z0-9])?\z/
    DID_FORMAT = /\Adid:(plc:[a-z2-7]{24}|web:[a-z0-9.-]+)\z/
    PLC_DIRECTORY = 'https://plc.directory'
    HANDLE_RESOLVER = 'https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle'

    attr_reader :did, :handle, :pds

    def self.resolve(input)
      new(input).tap(&:resolve)
    end

    def initialize(input)
      @handle = input.to_s.strip.delete_prefix('@').downcase
    end

    def resolve
      raise Error, 'not a valid handle' unless HANDLE_FORMAT.match?(handle) && handle.length <= 253

      @did = did_for_handle
      document = did_document(did)
      raise Error, 'handle does not match the account' unless Array(document['alsoKnownAs']).include?("at://#{handle}")

      @pds = pds_endpoint(document)
    end

    private

    # The handle's own domain is the authority; the Bluesky resolver is a fallback
    # for handles that prove themselves with a DNS record. Whichever answers, the
    # DID document has to point back at the handle.
    def did_for_handle
      candidates = [
        -> { Http.get("https://#{handle}/.well-known/atproto-did").strip },
        -> { Http.get_json("#{HANDLE_RESOLVER}?handle=#{CGI.escape(handle)}")['did'] }
      ]
      candidates.each do |lookup|
        did = lookup.call
        return did if DID_FORMAT.match?(did.to_s)
      rescue Http::Error
        next
      end
      raise Error, 'handle could not be resolved'
    end

    def did_document(did)
      url = did.start_with?('did:plc:') ? "#{PLC_DIRECTORY}/#{did}" : "https://#{did.delete_prefix('did:web:')}/.well-known/did.json"
      document = Http.get_json(url)
      raise Error, 'DID document is for someone else' unless document['id'] == did

      document
    rescue Http::Error => e
      raise Error, e.message
    end

    def pds_endpoint(document)
      service = Array(document['service']).find { |s| s['id'] == '#atproto_pds' && s['type'] == 'AtprotoPersonalDataServer' }
      endpoint = service && service['serviceEndpoint']
      raise Error, 'account has no PDS' unless endpoint.to_s.start_with?('https://')

      endpoint
    end
  end
end
