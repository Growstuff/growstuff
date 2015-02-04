module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, :as => :likeable, :dependent => :destroy
    has_many :members, :through => :likes
  end

end