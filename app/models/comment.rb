class Comment < ActiveRecord::Base
  attr_accessible :author_id, :body, :post_id
end
