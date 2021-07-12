class RedirectToPreviousUrlController < ApplicationController
  def show
    redirect_to after_sign_in_path_for(nil)
  end
end
