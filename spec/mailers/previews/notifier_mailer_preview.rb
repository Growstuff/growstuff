# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotifierMailerPreview < ActionMailer::Preview
  def harvest_reminder
    NotifierMailer.with(member: member).harvest_reminder(member)
  end

  private

  def member
    @member ||= FactoryBot.create(:member)
  end
end
