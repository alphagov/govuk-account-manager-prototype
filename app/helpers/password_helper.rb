module PasswordHelper
  def password_valid?(password, password_confirm)
    errors = []

    errors << :password_missing if password.blank?
    errors << :password_confirm_missing if password_confirm.blank?
    errors << :password_mismatch if password.present? && password_confirm.present? && password != password_confirm
    errors << :password_invalid if password.present? && !password_meets_criteria?(password)

    errors
  end

private

  def password_meets_criteria?(password)
    password.length >= 8 && password.match(/[0-9]/)
  end
end
