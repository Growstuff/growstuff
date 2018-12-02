class Container < ActiveRecord::Base
  extend FriendlyId
  friendly_id :container_slug, use: %i(slugged finders)

  has_many :plots, dependent: :destroy
  has_many :gardens, through: :plots

  validates :description, presence: true, uniqueness: true

  def container_slug
    "#{self.description}".gsub!(/[^A-Za-z ]/, '')
  end

  def subtitler(container)
    num = container.gardens.uniq.count
    s = num > 1 || num.zero? ? "s are" : " is"
    "#{num} garden#{s} using this container"
  end
end
