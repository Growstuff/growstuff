class Container < ActiveRecord::Base
  has_many :plots, dependent: :destroy
  has_many :gardens, through: :plots

  validates :description, presence: true, uniqueness: true

  def subtitler(container)
    num = container.gardens.uniq.count
    s = (num > 1 || num == 0) ? "s are" : " is"
    return "#{num.to_s} garden#{s} using this container"
  end
end
