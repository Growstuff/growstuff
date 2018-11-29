class Container < ActiveRecord::Base
  has_many :plots, dependent: :destroy
  has_many :gardens, through: :plots

  validates :description,
    format: {
      with: /\A\w+[\w ()]+\z/
    },
    length: { maximum: 255 },
    presence: true,
    uniqueness: true
end
