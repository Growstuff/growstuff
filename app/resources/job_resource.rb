# frozen_string_literal: true

class JobResource < ApplicationResource
  self.model = Job

  attribute :name, :string
  attribute :description, :string
  attribute :finished, :boolean
  attribute :due_date, :date
  attribute :jobbable_type, :string
  attribute :jobbable_id, :integer
  attribute :action, :string

  attribute :garden_id, :integer, readable: false

  belongs_to :garden
  owned
end
