module AcceptsJwt
  extend ActiveSupport::Concern

  def find_or_create_jwt(payload = nil)
    @find_or_create_jwt ||=
      begin
        jwt_from_state = Jwt.find_by(id: oauth_state_param) if oauth_state_param
        if jwt_from_state
          jwt_from_state.tap { |j| session[:jwt_id] = j.id }
        elsif payload
          Jwt.create!(jwt_payload: payload).tap { |j| session[:jwt_id] = j.id }
        elsif session[:jwt_id]
          Jwt.find_by(id: session[:jwt_id]) || session.delete(:jwt_id) && Jwt::Nil.new
        else
          Jwt::Nil.new
        end
      end
  end

  def oauth_state_param
    return unless params[:previous_url]&.start_with? oauth_authorization_path

    bits = params[:previous_url].split("?")
    return unless bits.length > 1

    querystring = CGI.parse(bits[1])
    querystring["state"]&.first&.split(":")&.first
  end
end
