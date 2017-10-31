ActionDispatch::Callbacks.after do
  # Reload the factories
  return unless Rails.env.development? || Rails.env.test?

  unless FactoryBot.factories.blank? # first init will load factories, this should only run on subsequent reloads
    FactoryBot.factories.clear
    FactoryBot.find_definitions
  end
end
