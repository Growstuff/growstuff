# frozen_string_literal: true

class AddReferralCodeToOrder < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :referral_code, :string
  end
end
