class CustomFailureApp < Devise::FailureApp
  def redirect_url
    new_user_session_url(previous_url: params.fetch(:previous_url, attempted_path))
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
