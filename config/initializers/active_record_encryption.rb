# frozen_string_literal: true

# Active Record Encryption (`encrypts`) needs a key and a salt, which the app has not
# had to provide until now. MastodonClient uses it to keep other servers' client secrets
# out of the database in plain text.
#
# A deployment can provide its own, in the credentials or with
# ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY and ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
# (`bin/rails db:encryption:init` makes some). Otherwise they are derived from the app's
# secret key base, which is already secret and already has to be kept stable. If it ever
# changes, stored secrets can no longer be read, and MastodonClientService simply
# registers with those servers again.
encryption = Rails.application.config.active_record.encryption

{
  primary_key:         'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY',
  key_derivation_salt: 'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'
}.each do |option, variable|
  next if encryption[option].present? || Rails.application.credentials.dig(:active_record_encryption, option).present?

  encryption[option] = ENV[variable].presence ||
                       Rails.application.key_generator.generate_key("active_record_encryption/#{option}").unpack1('H*')
end
