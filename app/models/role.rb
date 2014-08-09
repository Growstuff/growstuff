class Role < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  attr_accessible :description, :name, :members, :slug
  has_and_belongs_to_many :members

  def self.crop_wranglers
    Role.where(slug: 'crop-wrangler').try(:first).try(:members)
  end
end
