# frozen_string_literal: true

FactoryBot.define do
  # An app that signs members in with OAuth, such as the Android app: a public
  # client, so it has no secret.
  factory :oauth_application, class: 'Doorkeeper::Application' do
    sequence(:name) { |n| "App #{n}" }
    redirect_uri { 'org.growstuff.test:/oauth2redirect' }
    confidential { false }
    scopes { 'read write' }
  end

  factory :oauth_access_token, class: 'Doorkeeper::AccessToken' do
    application factory: :oauth_application
    resource_owner_id { create(:member).id }
    scopes { 'read write' }
    expires_in { 1.hour.to_i }
  end
end
