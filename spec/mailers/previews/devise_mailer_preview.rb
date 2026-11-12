# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(member, "faketoken")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(member, "faketoken")
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(member, "faketoken")
  end

  def email_changed
    Devise::Mailer.email_changed(member)
  end

  def password_change
    Devise::Mailer.password_change(member)
  end

  private

  def member
    FactoryBot.create(:member, locale: params[:locale])
  end
end
