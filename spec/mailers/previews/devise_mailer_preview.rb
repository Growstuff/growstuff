# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseMailer.confirmation_instructions(member, "faketoken")
  end

  def reset_password_instructions
    DeviseMailer.reset_password_instructions(member, "faketoken")
  end

  def unlock_instructions
    DeviseMailer.unlock_instructions(member, "faketoken")
  end

  private

  def member
    FactoryBot.create(:member, locale: params[:locale])
  end
end
