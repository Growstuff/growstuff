# frozen_string_literal: true

class MastodonClient < ApplicationRecord
  encrypts :client_secret

  validates :domain, :client_id, :client_secret, :redirect_uri, presence: true
  validates :domain, uniqueness: true
end
