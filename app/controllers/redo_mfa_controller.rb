class RedoMfaController < ApplicationController
  def stop
    session.delete(:after_redo_mfa_url)

    redirect_to account_manage_path
  end
end
