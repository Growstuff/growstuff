class Authentication < ActiveRecord::Base
  attr_accessible :member_id, :provider, :secret, :uid
end
