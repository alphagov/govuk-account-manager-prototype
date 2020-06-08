module KeycloakAdmin
  class UserClient
    def consents(user_id)
      response = execute_http do
        RestClient::Resource.new(consents_url(user_id), @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |hash| ConsentRepresentation.from_hash(hash) }
    end

    def sessions(user_id)
      response = execute_http do
        RestClient::Resource.new(sessions_url(user_id), @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |hash| SessionRepresentation.from_hash(hash) }
    end

    def consents_url(user_id)
      raise "user_id must be defined" if user_id.nil?

      "#{users_url(user_id)}/consents"
    end

    def sessions_url(user_id)
      raise "user_id must be defined" if user_id.nil?

      "#{users_url(user_id)}/sessions"
    end
  end

  class ConsentRepresentation < Representation
    def self.from_hash(*)
      # implement this when we have something generating consents
      raise "unimplemented"
    end
  end

  class SessionRepresentation < Representation
    attr_accessor :id,
                  :username,
                  :user_id,
                  :ip_address,
                  :start,
                  :last_access,
                  :clients

    def self.from_hash(hash)
      session = new
      session.id = hash["id"]
      session.username = hash["username"]
      session.user_id = hash["userId"]
      session.ip_address = hash["ipAddress"]
      session.start = hash["start"]
      session.last_access = hash["lastAccess"]
      session.clients = hash["clients"]
      session
    end
  end
end
