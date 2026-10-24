# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    subject { Faker::Book.title }

    body { Faker::Lorem.paragraphs.join("\n") }
    author
    created_at { Time.zone.now }

    # Markdown is allowed in posts
    factory :markdown_post do
      body { "This is some **strong** text." }
    end

    # HTML isn't allowed in posts
    factory :html_post do
      body { '<a href="http://evil.com">EVIL</a>' }
    end

    factory :forum_post do
      forum
    end
  end
end
