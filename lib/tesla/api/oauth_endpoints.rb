# frozen_string_literal: true

module Tesla
  module API
    # The OAuth 2.0 endpoints of Tesla's authorization server, which issue the tokens requests are authorized with
    #
    # An application is created at developer.tesla.com, which issues its client ID and client secret, and is
    # registered in a region once (see {PartnerEndpoints#register_partner}). A user is then sent to
    # {#authorization_url}, and comes back to the redirect URI with a code that {#exchange_code} exchanges for an
    # access token and a refresh token. The access token lasts eight hours, and the client asks for another with
    # the refresh token when it runs out (see {#refresh_access_token}).
    #
    # The requests are built by the simple_oauth gem, and the tokens are its `SimpleOAuth::OAuth2::Token`.
    #
    # @api public
    module OAuthEndpoints
      # The scopes a user is asked for by default, which are the ones the endpoints of the library need
      #
      # @api public
      SCOPES = %w[openid offline_access user_data vehicle_device_data vehicle_location vehicle_cmds
        vehicle_charging_cmds].freeze

      # The scopes a partner token is asked for by default
      #
      # @api public
      PARTNER_SCOPES = %w[openid vehicle_device_data vehicle_cmds vehicle_charging_cmds].freeze

      # The URL a user is sent to in order to authorize the application
      #
      # The state is a value of your own that the authorization server hands back with the code, to be compared
      # with the one sent (see `SimpleOAuth::OAuth2::AuthorizationResponse.parse`).
      #
      # @api public
      # @authenticated false
      # @param state [String] A random value that ties the response of the authorization server to this request.
      # @param pkce [SimpleOAuth::OAuth2::PKCE, nil] A PKCE challenge, whose verifier is given to {#exchange_code}.
      # @param scope [Array<String>, String] The scopes to ask the user for.
      # @param params [Hash] Other parameters of the authorization request, such as `prompt_missing_scopes`.
      # @return [String] the URL
      # @raise [ArgumentError] if the client has no client ID, or the state is empty
      # @example
      #   Tesla.authorization_url(state: SecureRandom.hex)
      def authorization_url(state:, pkce: nil, scope: SCOPES, **params)
        oauth_client.authorization_url(redirect_uri: required_redirect_uri, pkce:, state:, scope:, params:)
      end

      # Exchange an authorization code for an access token and a refresh token
      #
      # The code is the one the authorization server sent the user back to the redirect URI with.
      #
      # The client keeps the tokens, and authorizes its requests with them from then on.
      #
      # @api public
      # @authenticated false
      # @param code [String] The code the authorization server sent the user back to the redirect URI with.
      # @param code_verifier [String, nil] The verifier of the PKCE challenge the authorization URL was built with.
      # @return [SimpleOAuth::OAuth2::Token] the token
      # @raise [OAuthError] if the token endpoint turns the request away
      # @raise [ArgumentError] if the client has no client ID or no redirect URI
      # @example
      #   token = Tesla.exchange_code(params[:code])
      #   token.refresh_token
      def exchange_code(code, code_verifier: nil)
        request = oauth_client.authorization_code_request(code:, redirect_uri: required_redirect_uri, code_verifier:,
          params: {audience:})
        token = request_token(request)
        exclusively { store_token(token) }
      end

      # Ask for a new access token with the refresh token
      #
      # The client does this itself when the Fleet API answers that its access token is no longer good, so this is
      # for refreshing ahead of time. The client keeps the tokens it is answered with, the refresh token among
      # them, since a refresh token is used once.
      #
      # @api public
      # @authenticated false
      # @return [SimpleOAuth::OAuth2::Token] the token
      # @raise [OAuthError] if the token endpoint turns the request away
      # @raise [ArgumentError] if the client has no client ID or no refresh token
      # @example
      #   token = Tesla.refresh_access_token
      #   token.expires_at
      def refresh_access_token
        exclusively { refresh }
      end

      # Ask for a partner token
      #
      # A partner token authorizes the endpoints that act for the application rather than for a user.
      #
      # The client does not keep the token, since its own requests are authorized by a user.
      #
      # @api public
      # @authenticated false
      # @param scope [Array<String>, String] The scopes to ask for.
      # @return [SimpleOAuth::OAuth2::Token] the token
      # @raise [OAuthError] if the token endpoint turns the request away
      # @raise [ArgumentError] if the client has no client ID or no client secret
      # @example
      #   Tesla.partner_token.access_token
      def partner_token(scope: PARTNER_SCOPES)
        request_token(oauth_client.client_credentials_request(scope:, params: {audience:}))
      end

      private

      # The redirect URI of the client, which has to have one
      #
      # @api private
      # @return [String] the redirect URI
      # @raise [ArgumentError] if the client has no redirect URI
      def required_redirect_uri
        redirect_uri || raise(ArgumentError, "A redirect_uri is required to authorize a user")
      end
    end
  end
end
