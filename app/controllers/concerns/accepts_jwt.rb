module AcceptsJwt
  extend ActiveSupport::Concern

  def find_or_create_jwt(payload = nil)
    @find_or_create_jwt ||=
      if payload
        Jwt.create!(jwt_payload: payload).tap { |j| session[:jwt_id] = j.id }
      elsif session[:jwt_id]
        Jwt.find_by(id: session[:jwt_id]) || session.delete(:jwt_id) && nil
      end
  end
end
