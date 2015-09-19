namespace :i18n do
  desc "sort all locale keys"
  task normalize: :environment do
    `i18n-tasks normalize`
  end
end
