FactoryGirl.define do

  factory :post do
    subject "A Post"
    body "This is some text."
    member
    created_at Time.now

    # Markdown is allowed in posts
    factory :markdown_post do
      body "This is some **strong** text."
    end

    # HTML isn't allowed in posts
    factory :html_post do
      body '<a href="http://evil.com">EVIL</a>'
    end
  end

end
