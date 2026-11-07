# frozen_string_literal: true

module AlternateNamesHelper
  def alternate_name_language(alternate_name)
    return alternate_name.language if alternate_name.persisted? || alternate_name.language.present?

    language = current_member&.locale.to_s.split(/[-_]/).first&.upcase
    language if I18nData.languages.key?(language)
  end
end
