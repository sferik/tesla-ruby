# frozen_string_literal: true

RSpec.describe Tesla::API::OAuthEndpoints do
  let(:client) do
    Tesla::Client.new(client_id: TEST_CLIENT_ID, client_secret: TEST_CLIENT_SECRET, redirect_uri: TEST_REDIRECT_URI,
      refresh_token: TEST_REFRESH_TOKEN)
  end

  describe "::SCOPES" do
    it "names the scopes the endpoints of the library need" do
      expect(described_class::SCOPES).to eq(%w[openid offline_access user_data vehicle_device_data vehicle_location
        vehicle_cmds vehicle_charging_cmds])
    end

    it "is frozen" do
      expect(described_class::SCOPES).to be_frozen
    end
  end

  describe "::PARTNER_SCOPES" do
    it "names the scopes a partner token is asked for" do
      expect(described_class::PARTNER_SCOPES).to eq(%w[openid vehicle_device_data vehicle_cmds vehicle_charging_cmds])
    end

    it "is frozen" do
      expect(described_class::PARTNER_SCOPES).to be_frozen
    end
  end

  describe "#authorization_url" do
    def query_of(url)
      URI.decode_www_form(URI(url).query).to_h
    end

    it "is a URL of the authorization endpoint" do
      expect(client.authorization_url(state: "STATE")).to start_with("https://auth.tesla.com/oauth2/v3/authorize?")
    end

    it "asks for a code for the client, to be sent to the redirect URI, with the default scopes" do
      expect(query_of(client.authorization_url(state: "STATE"))).to eq("response_type" => "code",
        "client_id" => TEST_CLIENT_ID, "redirect_uri" => TEST_REDIRECT_URI, "state" => "STATE",
        "scope" => "openid offline_access user_data vehicle_device_data vehicle_location vehicle_cmds vehicle_charging_cmds")
    end

    it "asks for the scopes it is given" do
      expect(query_of(client.authorization_url(state: "STATE", scope: %w[openid vehicle_cmds])))
        .to include("scope" => "openid vehicle_cmds")
    end

    it "sends the challenge of the PKCE it is given" do
      pkce = SimpleOAuth::OAuth2::PKCE.generate

      expect(query_of(client.authorization_url(state: "STATE", pkce:)))
        .to include("code_challenge" => pkce.challenge, "code_challenge_method" => "S256")
    end

    it "sends the other parameters it is given" do
      expect(query_of(client.authorization_url(state: "STATE", prompt_missing_scopes: "true")))
        .to include("prompt_missing_scopes" => "true")
    end

    it "raises without a redirect URI" do
      client.redirect_uri = nil

      expect { client.authorization_url(state: "STATE") }
        .to raise_error(ArgumentError, "A redirect_uri is required to authorize a user")
    end

    it "raises without a client ID" do
      client.client_id = nil

      expect { client.authorization_url(state: "STATE") }.to raise_error(ArgumentError, /\AA client_id is required/)
    end
  end

  describe "#exchange_code" do
    before { stub_token }

    it "asks the token endpoint to exchange the code, for the audience of the client" do
      client.exchange_code("CODE")

      expect(a_token_request.with(body: {grant_type: "authorization_code", code: "CODE", redirect_uri: TEST_REDIRECT_URI,
                                         client_id: TEST_CLIENT_ID, client_secret: TEST_CLIENT_SECRET, audience: TEST_HOST}))
        .to have_been_made
    end

    it "sends the verifier of the PKCE challenge it is given" do
      client.exchange_code("CODE", code_verifier: "VERIFIER")

      expect(a_token_request.with(body: hash_including(code_verifier: "VERIFIER"))).to have_been_made
    end

    it "sends the audience of the client when it is not its host" do
      client.audience = Tesla::Configuration::EUROPE_HOST
      client.exchange_code("CODE")

      expect(a_token_request.with(body: hash_including(audience: Tesla::Configuration::EUROPE_HOST))).to have_been_made
    end

    it "returns the token" do
      expect(client.exchange_code("CODE")).to be_an_instance_of(SimpleOAuth::OAuth2::Token)
        .and have_attributes(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN")
    end

    it "keeps the tokens it is answered with" do
      client.exchange_code("CODE")

      expect(client).to have_attributes(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN")
    end

    it "keeps the tokens while it holds them, so that no other thread refreshes them meanwhile" do
      allow(client).to receive(:store_token) { expect(client.instance_variable_get(:@token_mutex)).to be_locked }

      client.exchange_code("CODE")
    end

    it "does not call on_token_refresh, since nothing was refreshed" do
      client.on_token_refresh = ->(_token) { raise "unreached" }

      expect { client.exchange_code("CODE") }.not_to raise_error
    end

    it "raises without a redirect URI" do
      client.redirect_uri = nil

      expect { client.exchange_code("CODE") }
        .to raise_error(ArgumentError, "A redirect_uri is required to authorize a user")
    end

    it "raises an OAuthError when the token endpoint turns the code away" do
      stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(status: 400, body: '{"error":"invalid_grant"}')

      expect { client.exchange_code("CODE") }.to raise_error(Tesla::OAuthError, "invalid_grant")
    end
  end

  describe "#refresh_access_token" do
    before { stub_token }

    it "asks the token endpoint for a token with the refresh token" do
      client.refresh_access_token

      expect(a_token_request.with(body: hash_including(grant_type: "refresh_token", refresh_token: TEST_REFRESH_TOKEN)))
        .to have_been_made
    end

    it "returns the token" do
      expect(client.refresh_access_token).to have_attributes(access_token: "NEW_ACCESS_TOKEN")
    end

    it "keeps the tokens it is answered with" do
      client.refresh_access_token

      expect(client).to have_attributes(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN")
    end

    it "refreshes while it holds the tokens of the client, so that no other thread refreshes them too" do
      allow(client).to receive(:refresh) { expect(client.instance_variable_get(:@token_mutex)).to be_locked }

      client.refresh_access_token
    end

    it "raises without a refresh token" do
      client.refresh_token = nil

      expect { client.refresh_access_token }.to raise_error(ArgumentError, /\AA refresh_token is required/)
    end
  end

  describe "#partner_token" do
    before { stub_token(access_token: "PARTNER_TOKEN", refresh_token: nil) }

    it "asks the token endpoint for a token with the credentials of the client, for its audience" do
      client.partner_token

      expect(a_token_request.with(body: {grant_type: "client_credentials", client_id: TEST_CLIENT_ID,
                                         client_secret: TEST_CLIENT_SECRET, audience: TEST_HOST,
                                         scope: "openid vehicle_device_data vehicle_cmds vehicle_charging_cmds"}))
        .to have_been_made
    end

    it "asks for the scopes it is given" do
      client.partner_token(scope: "openid")

      expect(a_token_request.with(body: hash_including(scope: "openid"))).to have_been_made
    end

    it "returns the token" do
      expect(client.partner_token).to have_attributes(access_token: "PARTNER_TOKEN")
    end

    it "does not keep the token, since the requests of the client are authorized by a user" do
      client.partner_token

      expect(client).to have_attributes(access_token: nil, refresh_token: TEST_REFRESH_TOKEN)
    end

    it "raises without a client secret" do
      client.client_secret = nil

      expect { client.partner_token }.to raise_error(ArgumentError, "The client credentials grant requires a client secret")
    end
  end
end
