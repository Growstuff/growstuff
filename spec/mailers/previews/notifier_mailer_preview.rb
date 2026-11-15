# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotifierMailerPreview < ActionMailer::Preview
  def planting_reminder
    NotifierMailer.with(member: member).planting_reminder(member)
  end

  def harvest_reminder
    NotifierMailer.with(member: member).harvest_reminder(member)
  end

  private

  def member
    @member ||= begin
      tomato = FactoryBot.create(:tomato)
      photo_url = "https://farm8.staticflickr.com/7856/#{Faker::Internet.username}"
      owner = FactoryBot.create(:interesting_member, locale: params[:locale], login_name: Faker::Internet.username(separators: ['_']))
      planting = FactoryBot.create(:planting, owner:, garden: owner.gardens.first)
      photo = FactoryBot.create(:photo, owner:,
                                        thumbnail_url: "#{photo_url}_q.jpg", fullsize_url: "#{photo_url}_z.jpg")
      planting.photos << photo

      harvest = FactoryBot.create(:harvest, crop: tomato, owner:)
      harvest.photos << photo
      FactoryBot.create(:planting, crop: tomato,
                                   planted_at: 1.year.ago, finished_at: 2.months.ago,
                                   sunniness: 'sun', planted_from: 'seed')
      owner
    end
  end
end
