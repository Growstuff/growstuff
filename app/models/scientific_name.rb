# frozen_string_literal: true

class ScientificName < ActiveRecord::Base
  after_commit { |sn| sn.crop.__elasticsearch__.index_document if sn.crop && ENV['GROWSTUFF_ELASTICSEARCH'] == "true" }
  belongs_to :crop
  belongs_to :creator, class_name: 'Member'
  validates :name, presence: true
  validates :crop, presence: true
end
