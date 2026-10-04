# frozen_string_literal: true

RSpec.describe Tesla::BearerTokenAuthenticator do
  subject(:authenticator) { described_class.new(access_token: TEST_ACCESS_TOKEN) }

  let(:request) { Net::HTTP::Get.new(URI("https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/vehicles")) }

  it "is an Authenticator" do
    expect(authenticator).to be_a(Tesla::Authenticator)
  end

  describe "#access_token" do
    it "exposes the access token" do
      expect(authenticator.access_token).to eq(TEST_ACCESS_TOKEN)
    end
  end

  describe "#header" do
    it "authorizes the request with the access token as a bearer token" do
      expect(authenticator.header(request)).to eq("Authorization" => "Bearer #{TEST_ACCESS_TOKEN}")
    end
  end

  describe "#inspect" do
    it "leaves out the access token" do
      expect(authenticator.inspect).to eq("#<Tesla::BearerTokenAuthenticator>")
    end
  end
end
