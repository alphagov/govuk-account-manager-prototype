class CustomFailureApp < Devise::FailureApp
  def redirect_url
    new_user_session_url(previous_url: request.fullpath)
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
