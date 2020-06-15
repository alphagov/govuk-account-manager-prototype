module PasswordHelper
  def password_valid?(password, password_confirm)
    return :password_missing if password.blank?

    return :password_confirm_missing if password_confirm.blank?

    return :password_mismatch unless password == password_confirm

    return :password_invalid unless password_meets_criteria?(password)

    :ok
  end

private

  def password_meets_criteria?(password)
    password.length >= 8 && password.match(/[0-9]/)
  end
end
