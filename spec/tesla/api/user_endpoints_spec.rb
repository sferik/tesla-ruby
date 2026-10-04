# frozen_string_literal: true

RSpec.describe Tesla::API::UserEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#me" do
    before { stub_get("/api/1/users/me").to_return(body: fixture("me.json")) }

    it "gets the correct resource" do
      client.me

      expect(a_get("/api/1/users/me")).to have_been_made
    end

    it "returns the user" do
      expect(client.me).to be_an_instance_of(Tesla::User).and have_attributes(email: "nikola@example.com")
    end
  end

  describe "#region" do
    before { stub_get("/api/1/users/region").to_return(body: fixture("region.json")) }

    it "gets the correct resource" do
      client.region

      expect(a_get("/api/1/users/region")).to have_been_made
    end

    it "returns the region" do
      expect(client.region).to be_an_instance_of(Tesla::Region)
        .and have_attributes(region: "eu", fleet_api_base_url: Tesla::Configuration::EUROPE_HOST)
    end
  end
end
