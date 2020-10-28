class DeviseMailer < Devise::Mailer
  def email_changed(record, opts = {})
    if record.try(:unconfirmed_email?)
      devise_mail(record, :email_changing, opts)
    else
      devise_mail(record, :email_changed, opts)
    end
  end
end
