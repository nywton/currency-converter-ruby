module AuthHelpers
  # Generate a JWT for the given user and return headers for a JSON API request.
  # @param user [User] the user to generate the token for
  # @return [Hash<String,String>] headers including Authorization and Content-Type
  def auth_headers_for(user)
    token = ApplicationController.new.send(:issue_jwt, user)

    {
      "Authorization" => "Bearer #{token}",
      "Content-Type"  => "application/json"
    }
  end
end
