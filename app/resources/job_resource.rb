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
  filter_only :owner_id, :integer

  belongs_to :garden
  belongs_to :owner, resource: MemberResource
end
