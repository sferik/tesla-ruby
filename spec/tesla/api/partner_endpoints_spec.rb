# frozen_string_literal: true

RSpec.describe Tesla::API::PartnerEndpoints do
  let(:client) do
    Tesla::Client.new(access_token: TEST_ACCESS_TOKEN, client_id: TEST_CLIENT_ID, client_secret: TEST_CLIENT_SECRET)
  end
  let(:public_key) { JSON.parse(fixture("public_key.json").read).dig("response", "public_key") }

  before { stub_token(access_token: "PARTNER_TOKEN", refresh_token: nil) }

  describe "#register_partner" do
    before { stub_post("/api/1/partner_accounts").to_return(body: fixture("partner_account.json")) }

    it "posts the domain to the correct resource" do
      client.register_partner("example.com")

      expect(a_post("/api/1/partner_accounts").with(body: {domain: "example.com"})).to have_been_made
    end

    it "authorizes the request with a partner token rather than the access token of the client" do
      client.register_partner("example.com")

      expect(a_post("/api/1/partner_accounts").with(headers: {"Authorization" => "Bearer PARTNER_TOKEN"})).to have_been_made
    end

    it "returns the account the application is registered as" do
      expect(client.register_partner("example.com")).to include("domain" => "example.com", "public_key" => public_key)
    end

    it "leaves the access token of the client as it was" do
      client.register_partner("example.com")

      expect(client.access_token).to eq(TEST_ACCESS_TOKEN)
    end
  end

  describe "#partner_public_key" do
    let(:path) { "/api/1/partner_accounts/public_key?domain=example.com" }

    before { stub_get(path).to_return(body: fixture("public_key.json")) }

    it "gets the correct resource" do
      client.partner_public_key("example.com")

      expect(a_get(path)).to have_been_made
    end

    it "authorizes the request with a partner token rather than the access token of the client" do
      client.partner_public_key("example.com")

      expect(a_get(path).with(headers: {"Authorization" => "Bearer PARTNER_TOKEN"})).to have_been_made
    end

    it "returns the public key" do
      expect(client.partner_public_key("example.com")).to eq(public_key)
    end

    it "raises InvalidResponse for a response without a public key" do
      stub_get(path).to_return(body: '{"response":{}}')

      expect { client.partner_public_key("example.com") }
        .to raise_error(Tesla::InvalidResponse, 'The response body is not the expected JSON: key not found: "public_key"')
    end
  end
end
