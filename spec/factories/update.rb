FactoryGirl.define do

  factory :update do
    subject "An Update"
    body "This is some text."
    user

    # Markdown is allowed in updates
    factory :markdown_update do
      body "This is some **strong** text."
    end

    # HTML isn't allowed in updates
    factory :html_update do
      body '<a href="http://evil.com">EVIL</a>'
    end
  end

end
