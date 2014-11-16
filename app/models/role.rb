class Role < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]
  attr_accessible :description, :name, :members, :slug
  has_and_belongs_to_many :members

  class << self
    [:crop_wranglers, :admins].each do |method|
      define_method method do
        slug = method.to_s.singularize.dasherize
        Role.where(slug: slug).try(:first).try(:members)
      end
    end
  end
end
