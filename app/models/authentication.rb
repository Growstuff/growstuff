# frozen_string_literal: true

class Authentication < ActiveRecord::Base
  belongs_to :member
end
