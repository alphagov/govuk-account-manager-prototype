class DeviseMailer < Devise::Mailer
  def confirmation_instructions(record, token, opts = {})
    @token = token
    if record.try(:unconfirmed_email?)
      devise_mail(record, :change_confirmation_instructions, opts)
    else
      devise_mail(record, :confirmation_instructions, opts)
    end
  end

  def email_changed(record, opts = {})
    if record.try(:unconfirmed_email?)
      devise_mail(record, :email_changing, opts)
    else
      devise_mail(record, :email_changed, opts)
    end
  end
end
