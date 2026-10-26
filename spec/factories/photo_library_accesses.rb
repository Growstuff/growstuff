# frozen_string_literal: true

FactoryBot.define do
  factory :photo_library_access do
    member
    request_message { 'Photos of my vegetable garden' }

    factory :approved_photo_library_access do
      status { 'approved' }
      decided_by factory: :admin_member
      decided_at { Time.zone.now }
    end
  end
end
