# frozen_string_literal: true

RSpec.describe Tesla::ClientCredentials do
  let(:client) do
    Tesla::Client.new(access_token: TEST_ACCESS_TOKEN, refresh_token: TEST_REFRESH_TOKEN, client_id: TEST_CLIENT_ID,
      client_secret: TEST_CLIENT_SECRET, redirect_uri: TEST_REDIRECT_URI, max_retries: 0)
  end

  %i[access_token refresh_token client_id client_secret redirect_uri authorization_endpoint token_endpoint
    on_token_refresh].each do |setting|
    describe "##{setting}=" do
      it "assigns the #{setting.to_s.tr("_", " ")}" do
        client.public_send(:"#{setting}=", "ASSIGNED")

        expect(client.public_send(setting)).to eq("ASSIGNED")
      end
    end
  end

  describe "#audience" do
    it "is the host of the client by default" do
      expect(client.audience).to eq(TEST_HOST)
    end

    it "follows the host of the client" do
      client.host = Tesla::Configuration::EUROPE_HOST

      expect(client.audience).to eq(Tesla::Configuration::EUROPE_HOST)
    end

    it "is the audience it was assigned" do
      client.host = "https://localhost:4443"
      client.audience = Tesla::Configuration::EUROPE_HOST

      expect(client.audience).to eq(Tesla::Configuration::EUROPE_HOST)
    end
  end

  describe "#authenticator_for" do
    it "authorizes a request with an access token as a bearer token" do
      expect(client.send(:authenticator_for, "TOKEN"))
        .to be_an_instance_of(Tesla::BearerTokenAuthenticator).and have_attributes(access_token: "TOKEN")
    end

    it "sends a request without an access token unauthorized" do
      expect(client.send(:authenticator_for, nil)).to be_an_instance_of(Tesla::Authenticator)
    end
  end

  describe "#refreshable?" do
    it "is true for a client with a refresh token and a client ID" do
      expect(client.send(:refreshable?)).to be(true)
    end

    it "is false for a client without a refresh token" do
      client.refresh_token = nil

      expect(client.send(:refreshable?)).to be(false)
    end

    it "is false for a client without a client ID" do
      client.client_id = nil

      expect(client.send(:refreshable?)).to be(false)
    end
  end

  describe "#exclusively" do
    it "returns what the block returns" do
      expect(client.send(:exclusively) { :held }).to eq(:held)
    end

    it "holds the tokens of the client while the block runs" do
      client.send(:exclusively) { expect(client.instance_variable_get(:@token_mutex)).to be_locked }
    end

    it "lets go of the tokens once the block is done" do
      client.send(:exclusively) { :held }

      expect(client.instance_variable_get(:@token_mutex)).not_to be_locked
    end
  end

  describe "#renewed_access_token" do
    before { stub_token }

    it "is the access token of the client when it is not the stale one" do
      expect(client.send(:renewed_access_token, nil)).to eq(TEST_ACCESS_TOKEN)
    end

    it "does not refresh an access token that is not the stale one" do
      client.send(:renewed_access_token, "OLDER_ACCESS_TOKEN")

      expect(a_token_request).not_to have_been_made
    end

    it "refreshes the access token when it is the stale one" do
      expect(client.send(:renewed_access_token, TEST_ACCESS_TOKEN.dup)).to eq("NEW_ACCESS_TOKEN")
    end

    it "asks for the first access token of a client that has none" do
      client.access_token = nil

      expect(client.send(:renewed_access_token, nil)).to eq("NEW_ACCESS_TOKEN")
    end

    it "does not refresh the stale access token of a client that cannot" do
      client.refresh_token = nil
      client.send(:renewed_access_token, TEST_ACCESS_TOKEN)

      expect(a_token_request).not_to have_been_made
    end

    it "is the stale access token for a client that cannot refresh it" do
      client.client_id = nil

      expect(client.send(:renewed_access_token, TEST_ACCESS_TOKEN)).to eq(TEST_ACCESS_TOKEN)
    end

    it "is nil for a client without an access token that cannot ask for one" do
      client.access_token = client.refresh_token = nil

      expect(client.send(:renewed_access_token, nil)).to be_nil
    end

    it "refreshes while it holds the tokens of the client, so that no other thread refreshes them too" do
      allow(client).to receive(:refresh) { expect(client.instance_variable_get(:@token_mutex)).to be_locked }

      client.send(:renewed_access_token, TEST_ACCESS_TOKEN)
    end
  end

  describe "#refresh" do
    before { stub_token }

    it "asks the token endpoint for a token with the refresh token" do
      client.send(:refresh)

      expect(a_token_request.with(body: {grant_type: "refresh_token", refresh_token: TEST_REFRESH_TOKEN,
                                         client_id: TEST_CLIENT_ID, client_secret: TEST_CLIENT_SECRET})).to have_been_made
    end

    it "returns the token" do
      expect(client.send(:refresh)).to be_an_instance_of(SimpleOAuth::OAuth2::Token)
        .and have_attributes(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN", expires_in: 28_800)
    end

    it "keeps the access token and the refresh token it is answered with" do
      client.send(:refresh)

      expect(client).to have_attributes(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN")
    end

    it "calls on_token_refresh with the token" do
      refreshed = []
      client.on_token_refresh = ->(token) { refreshed << token }
      token = client.send(:refresh)

      expect(refreshed).to eq([token])
    end

    it "calls on_token_refresh once the client has the tokens" do
      client.on_token_refresh = ->(_token) { expect(client.refresh_token).to eq("NEW_REFRESH_TOKEN") }

      client.send(:refresh)
    end

    it "raises without a refresh token" do
      client.refresh_token = nil

      expect { client.send(:refresh) }
        .to raise_error(ArgumentError, "A refresh_token is required to refresh the access token")
    end

    it "does not ask for a token without a refresh token" do
      client.refresh_token = nil
      client.send(:refresh)
    rescue ArgumentError
      expect(a_token_request).not_to have_been_made
    end
  end

  describe "#store_token" do
    let(:token) { SimpleOAuth::OAuth2::Token.new({"access_token" => "NEW_ACCESS_TOKEN"}) }

    it "returns the token" do
      expect(client.send(:store_token, token)).to equal(token)
    end

    it "keeps the access token" do
      client.send(:store_token, token)

      expect(client.access_token).to eq("NEW_ACCESS_TOKEN")
    end

    it "keeps the refresh token the response carries" do
      client.send(:store_token, SimpleOAuth::OAuth2::Token.new({"access_token" => "A", "refresh_token" => "R"}))

      expect(client.refresh_token).to eq("R")
    end

    it "keeps the refresh token as it was when the response carries none" do
      client.send(:store_token, token)

      expect(client.refresh_token).to eq(TEST_REFRESH_TOKEN)
    end
  end

  describe "#oauth_client" do
    it "builds an OAuth 2.0 client from the credentials and the endpoints of the client" do
      expect(client.send(:oauth_client)).to be_an_instance_of(SimpleOAuth::OAuth2::Client)
        .and have_attributes(client_id: TEST_CLIENT_ID, client_secret: TEST_CLIENT_SECRET,
          authorization_endpoint: Tesla::Configuration::DEFAULT_AUTHORIZATION_ENDPOINT, token_endpoint: TEST_TOKEN_ENDPOINT)
    end

    it "sends the client secret in the body of a request" do
      expect(client.send(:oauth_client).auth_method).to eq(:client_secret_post)
    end

    it "raises without a client ID" do
      client.client_id = nil

      expect { client.send(:oauth_client) }
        .to raise_error(ArgumentError, "A client_id is required to ask the authorization server for a token")
    end
  end

  describe "#request_token" do
    let(:oauth_request) { client.send(:oauth_client).refresh_token_request(refresh_token: TEST_REFRESH_TOKEN) }

    it "posts the request to the URL it names" do
      stub_token
      client.send(:request_token, oauth_request)

      expect(a_token_request.with(body: oauth_request.body)).to have_been_made
    end

    it "sends the headers of the request" do
      stub_token
      client.send(:request_token, oauth_request)

      expect(a_token_request.with(headers: {"Content-Type" => "application/x-www-form-urlencoded",
                                            "Accept" => "application/json"})).to have_been_made
    end

    it "sends the request without the access token of the client" do
      stub_token
      client.send(:request_token, oauth_request)

      expect(a_token_request.with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "returns the token the response carries" do
      stub_token

      expect(client.send(:request_token, oauth_request)).to have_attributes(access_token: "NEW_ACCESS_TOKEN")
    end

    it "raises an OAuthError for a response that reports an error" do
      stub_request(:post, TEST_TOKEN_ENDPOINT)
        .to_return(status: 401, body: '{"error":"invalid_grant","error_description":"The refresh token is expired."}')

      expect { client.send(:request_token, oauth_request) }
        .to raise_error(Tesla::OAuthError, "invalid_grant: The refresh token is expired.")
    end

    it "attaches the error code, the description, and the status to the error" do
      stub_request(:post, TEST_TOKEN_ENDPOINT)
        .to_return(status: 401, body: '{"error":"invalid_grant","error_description":"The refresh token is expired."}')

      expect { client.send(:request_token, oauth_request) }.to raise_error(
        having_attributes(code: "invalid_grant", description: "The refresh token is expired.", status: 401)
      )
    end

    it "keeps the error of simple_oauth as the cause" do
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(status: 400, body: '{"error":"invalid_request"}')

      expect { client.send(:request_token, oauth_request) }
        .to raise_error(having_attributes(cause: an_instance_of(SimpleOAuth::OAuth2::Error)))
    end

    it "raises an OAuthError for a response without a token" do
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(body: "{}")

      expect { client.send(:request_token, oauth_request) }
        .to raise_error(Tesla::OAuthError, "token response has no access_token")
    end

    it "raises an OAuthError that names the status for a response that describes no error" do
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(status: 503, body: "<html>")

      expect { client.send(:request_token, oauth_request) }
        .to raise_error(Tesla::OAuthError, "The token endpoint answered with status 503")
    end

    it "sends a request a rate limiter turned away again" do
      client.max_retries = 1
      allow(client.send(:retry_handler)).to receive(:sleep)
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return({status: 429, headers: {"Retry-After" => "1"}},
        {body: '{"access_token":"NEW_ACCESS_TOKEN"}'})

      expect(client.send(:request_token, oauth_request).access_token).to eq("NEW_ACCESS_TOKEN")
    end

    it "does not send a request that went unanswered again, since it may have used the refresh token" do
      client.max_retries = 1
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(status: 503)
      client.send(:request_token, oauth_request)
    rescue Tesla::OAuthError
      expect(a_token_request).to have_been_made.once
    end

    it "raises a NetworkError for a request the network lost" do
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_raise(Errno::ECONNRESET)

      expect { client.send(:request_token, oauth_request) }.to raise_error(Tesla::NetworkError)
    end
  end
end
