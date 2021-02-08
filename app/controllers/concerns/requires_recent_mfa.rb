module RequiresRecentMfa
  class MissingMfaMethod < StandardError; end

  extend ActiveSupport::Concern

  def has_done_mfa_recently?
    return true unless MultiFactorAuth.is_enabled?

    session[:has_done_mfa]
  end

  def redo_mfa(after_redo_mfa_url)
    session[:after_redo_mfa_url] = after_redo_mfa_url
    session.delete(:has_done_mfa)

    case MultiFactorAuth.choose_mfa_method(current_user)
    when :phone
      MultiFactorAuth.generate_and_send_code(current_user)
      redirect_to redo_mfa_phone_code_path
    else
      raise MissingMfaMethod, current_user.id
    end
  end
end
