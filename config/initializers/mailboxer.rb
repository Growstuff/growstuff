# frozen_string_literal: true

Mailboxer.setup do |config|
  # Configures if your application uses or not email sending for Notifications and Messages
  config.uses_emails = true

  # Configures the default from for emails sent for Messages and Notifications
  config.default_from = "no-reply@growstuff.org"

  # Configures the methods needed by mailboxer
  # config.email_method = :email
  config.name_method = :login_name
  config.notify_method = :notify

  # Configures if you use or not a search engine and which one you are using
  # Supported engines: [:solr,:sphinx,:pg_search]
  # config.search_enabled = false
  # config.search_engine = :solr

  # Configures maximum length of the message subject and body
  config.subject_max_length = 255
  config.body_max_length = 32_000
end
