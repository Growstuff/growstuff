class AlternateName < ActiveRecord::Base
  after_commit { |an| an.crop.__elasticsearch__.index_document if an.crop && ENV['GROWSTUFF_ELASTICSEARCH'] == "true" }
  belongs_to :crop
  belongs_to :creator, class_name: 'Member'
end
