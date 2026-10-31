# frozen_string_literal: true

class MastodonClient < ApplicationRecord
  encrypts :client_secret
end
