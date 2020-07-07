require "services"

class LoginController < ApplicationController
  def show
    # users should be sent here with omniauth params in the URL
    unless oidc_params[:client_id]
      redirect_to "/auth/oidc?return_to=/account"
      return
    end

    # check if the user already has a session
    r = get_login_form(oidc_endpoint, oidc_params)
    if r[:state] == :ok
      redirect_to r[:redirect_uri]
      return
    end

    if login_params[:username]
      @state = :password_form
      @user_is_missing = Services.keycloak.users.search(login_params[:username]).first.nil?
    else
      @state = :username_form
    end

    # persist the `oidc_params` in the form
    @extra_params = query_string(oidc_params)
  end

  def submit
    unless request_errors.empty?
      flash[:validation] = request_errors
      redirect_to action: :show, params: login_params
      return
    end

    # TODO: think about how to fix the IP geolocation, if all the
    # requests to keycloak's login endpoint come from the PaaS - is
    # there a header we can set to trasmit the original IP?
    r1 = get_login_form(oidc_endpoint, oidc_params)
    if r1[:state] == :ok
      redirect_to r1[:redirect_uri]
      return
    end

    form_params = {
      r1[:field_name_username] => login_params[:username],
      r1[:field_name_password] => login_params[:password],
    }
    r2 = post_login_form(r1[:form_action], form_params)

    case r2[:state]
    when :ok
      redirect_to r2[:redirect_uri]
    when :timed_out
      flash[:validation] = [] # TODO: something about "timed out!"
      redirect_to action: :show, params: login_params
    when :no_such_account
      flash[:validation] = [] # TODO: something about "no such account!"
      redirect_to action: :show, params: login_params
    when :bad_password
      flash[:validation] = [] # TODO: something about "bad password!"
      redirect_to action: :show, params: login_params
    when :needs_mfa
      @extra_params = query_string(
        form_action: r2[:form_action],
        field_name_mfa: r2[:field_name_mfa],
      )
      render "submit_mfa"
    end
  end

  def submit_mfa
    unless request_errors.empty?
      flash[:validation] = request_errors
      return
    end

    params = { login_params[:field_name_mfa] => login_params[:mfa_code] }
    r = post_mfa_form(login_params[:form_action], params)
    case r[:state]
    when :ok
      redirect_to r[:redirect_uri]
    when :timed_out
      flash[:validation] = [] # TODO: something about "timed out!"
      redirect_to action: :show, params: login_params
    when :bad_code
      @code_is_bad = true
    end
  end

private

  def submit_request_errors
    [] # TODO
  end

  def mfa_request_errors
    [] # TODO
  end

  def oidc_endpoint
    Services.discover.authorization_endpoint
  end

  def oidc_params
    {
      client_id: login_params[:client_id],
      nonce: login_params[:nonce],
      redirect_uri: login_params[:redirect_uri],
      response_type: login_params[:response_type],
      scope: login_params[:scope],
      state: login_params[:state],
    }
  end

  def login_params
    params.permit(:client_id, :nonce, :redirect_uri, :response_type, :scope, :state, :username, :password, :form_action, :mfa_code, :field_name_mfa)
  end

  def get_login_form(uri, params)
    resp = proxy_get(uri, params)

    if resp.redirection? && resp.headers["Location"].starts_with?(login_params[:redirect_uri])
      {
        state: :ok,
        redirect_uri: resp.headers["Location"],
      }
    else
      # TODO: scrape response (we should change the theme to be very
      # scraping-friendly)

      {
        form_action: nil,
        field_name_username: nil,
        field_name_password: nil,
      }
    end
  end

  def post_login_form(uri, params)
    resp = proxy_post(uri, params)

    if resp.redirection? && resp.headers["Location"].starts_with?(login_params[:redirect_uri])
      {
        state: :ok,
        redirect_uri: resp.headers["Location"],
      }
    else
      # TODO: scrape response (we should change the theme to be very
      # scraping-friendly)

      # if we waited too long
      {
        state: :timed_out,
      }

      # if the account doesn't exist
      {
        state: :no_such_account,
      }

      # if it does exist but the password is wrong
      {
        state: :bad_password,
      }

      # if there is a mfa form to submit
      {
        state: :needs_mfa,
        form_action: nil,
        field_name_mfa: nil,
      }
    end
  end

  def post_mfa_form(uri, params)
    resp = proxy_post(uri, params)

    if resp.redirection? && resp.headers["Location"].starts_with?(login_params[:redirect_uri])
      {
        state: :ok,
        redirect_uri: resp.headers["Location"],
      }
    else
      # TODO: scrape response (we should change the theme to be very
      # scraping-friendly)

      # if we waited too long
      {
        state: :timed_out,
      }

      # if the code is bad
      {
        state: :bad_code,
      }
    end
  end

  def query_string(params)
    Rack::Utils.build_nested_query(params)
  end

  def proxy_get(uri, params)
    resp = HTTParty.get(uri + "?" + query_string(params), headers: { "Cookie" => keycloak_cookies }.compact)
    set_keycloak_cookies(resp)
    resp
  end

  def proxy_post(uri, params)
    resp = HTTParty.post(uri, body: params, headers: { "Cookie" => keycloak_cookies }.compact)
    set_keycloak_cookies(resp)
    resp
  end

  def get_keycloak_cookies
    session[:keycloak_cookies]
  end

  def set_keycoak_cookies(resp)
    cookie_hash = CookieHash.new
    cookie_hash.add(session[:keycloak_cookies] || "")
    resp.get_fields("Set-Cookie").each { |c| cookie_hash.add(c) }
    session[:keycloak_cookies] = cookie_hash.to_cookie_string
  end
end
