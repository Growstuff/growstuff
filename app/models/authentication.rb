class Authentication < ActiveRecord::Base
  belongs_to :member
  attr_accessible :provider, :uid, :secret
end
