class Container < ActiveRecord::Base

  has_many :plots, dependent: :destroy
  has_many :gardens, through: :plots

  validates :description, presence: true, uniqueness: true
end
