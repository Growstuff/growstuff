class MastodonClient < ApplicationRecord
  encrypts :client_secret
end