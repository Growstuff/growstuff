class Comment < ActiveRecord::Base
  attr_accessible :author_id, :body, :post_id
  belongs_to :author, :class_name => 'Member'
  belongs_to :post
end
