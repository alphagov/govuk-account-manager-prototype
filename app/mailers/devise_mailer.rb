class DeviseMailer < Devise::Mailer
  def confirmation_instructions(record, token, opts = {})
    @token = token
    if record.confirmed? || record.unconfirmed_email?
      devise_mail(record, :change_confirmation_instructions, opts)
    else
      devise_mail(record, :confirmation_instructions, opts)
    end
  end
end
