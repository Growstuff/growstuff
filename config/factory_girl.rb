ActionDispatch::Callbacks.after do
  # Reload the factories
  return unless (Rails.env.development? || Rails.env.test?)

  unless FactoryGirl.factories.blank? # first init will load factories, this should only run on subsequent reloads
    FactoryGirl.factories.clear
    FactoryGirl.find_definitions
  end
end
