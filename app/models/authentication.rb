# frozen_string_literal: true

class Authentication < ApplicationRecord
  belongs_to :member

  attr_accessible :member_id, :provider, :uid, :token, :secret, :name
end
