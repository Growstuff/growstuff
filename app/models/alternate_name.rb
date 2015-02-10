class AlternateName < ActiveRecord::Base
  after_commit { |an| an.crop.__elasticsearch__.index_document if an.crop }
  belongs_to :crop
  belongs_to :creator, :class_name => 'Member'
end
