class DeviseUnlocksController < Devise::UnlocksController
  # POST /account/unlock
  def create
    super do
      if resource.errors.details[:email].first&.dig(:error) == :not_locked
        if current_user
          redirect_to user_root_path
        else
          redirect_to "/", flash: { notice: I18n.t("errors.messages.not_locked") }
        end
        return
      end
    end
  end
end
