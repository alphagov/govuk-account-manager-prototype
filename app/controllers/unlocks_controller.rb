class UnlocksController < Devise::UnlocksController
  # POST /account/unlock
  def create
    super do
      if resource.errors.details[:email].first&.dig(:error) == :not_locked
        if current_user
          redirect_to account_manage_path
        else
          redirect_to new_user_session_path, flash: { notice: I18n.t("errors.messages.not_locked") }
        end
        return
      end
    end
  end

  def show
    super do
      next unless resource.errors.empty?

      record_security_event(SecurityActivity::MANUAL_ACCOUNT_UNLOCK, user: resource)
    end
  end
end
