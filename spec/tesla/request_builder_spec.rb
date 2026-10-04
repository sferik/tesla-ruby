# frozen_string_literal: true

RSpec.describe Tesla::RequestBuilder do
  subject(:builder) { described_class.new }

  let(:uri) { URI("https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/vehicles") }

  describe "::DEFAULT_USER_AGENT" do
    it "names the library and its version" do
      expect(described_class::DEFAULT_USER_AGENT).to start_with("tesla/#{Tesla::VERSION} ")
    end

    it "names the Ruby it runs on" do
      expect(described_class::DEFAULT_USER_AGENT)
        .to eq("tesla/#{Tesla::VERSION} (#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION}; #{RUBY_PLATFORM})")
    end
  end

  describe "#initialize" do
    it "defaults the user agent" do
      expect(builder.user_agent).to eq(described_class::DEFAULT_USER_AGENT)
    end

    it "sets a custom user agent" do
      expect(described_class.new(user_agent: "Custom User Agent").user_agent).to eq("Custom User Agent")
    end
  end

  describe "#build" do
    {get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put, patch: Net::HTTP::Patch, delete: Net::HTTP::Delete}.each do |http_method, request_class|
      it "builds a #{http_method.upcase} request" do
        expect(builder.build(http_method:, uri:)).to be_an_instance_of(request_class)
      end
    end

    it "raises an ArgumentError for an unsupported HTTP method" do
      expect { builder.build(http_method: :head, uri:) }.to raise_error(ArgumentError, "Unsupported HTTP method: head")
    end

    it "sets the request URI" do
      expect(builder.build(http_method: :get, uri:).uri).to eq(uri)
    end

    it "sets the default User-Agent header" do
      expect(builder.build(http_method: :get, uri:)["User-Agent"]).to eq(described_class::DEFAULT_USER_AGENT)
    end

    it "uses the configured user agent" do
      builder.user_agent = "Custom User Agent"

      expect(builder.build(http_method: :get, uri:)["User-Agent"]).to eq("Custom User Agent")
    end

    it "adds custom headers" do
      request = builder.build(http_method: :get, uri:, headers: {"X-Custom" => "value"})

      expect(request["X-Custom"]).to eq("value")
    end

    it "lets custom headers override the defaults" do
      request = builder.build(http_method: :get, uri:, headers: {"User-Agent" => "Custom User Agent"})

      expect(request["User-Agent"]).to eq("Custom User Agent")
    end

    it "does not add an Authorization header without an authenticator" do
      expect(builder.build(http_method: :get, uri:)["Authorization"]).to be_nil
    end

    it "adds the authenticator's headers" do
      authenticator = Tesla::BearerTokenAuthenticator.new(access_token: TEST_ACCESS_TOKEN)

      expect(builder.build(http_method: :get, uri:, authenticator:)["Authorization"]).to eq("Bearer #{TEST_ACCESS_TOKEN}")
    end

    it "passes the request to the authenticator" do
      authenticator = instance_double(Tesla::Authenticator)
      allow(authenticator).to receive(:header).and_return({})
      builder.build(http_method: :get, uri:, authenticator:)

      expect(authenticator).to have_received(:header).with(an_instance_of(Net::HTTP::Get))
    end

    context "with query parameters" do
      it "appends the parameters to the URI" do
        request = builder.build(http_method: :get, uri:, params: {query: "cucumber", page: 2})

        expect(request.uri.query).to eq("query=cucumber&page=2")
      end

      it "does not add a query without parameters" do
        expect(builder.build(http_method: :get, uri:).uri.query).to be_nil
      end

      it "does not modify the original URI" do
        builder.build(http_method: :get, uri:, params: {query: "cucumber"})

        expect(uri.query).to be_nil
      end
    end

    it "lets custom headers override the headers of the authenticator" do
      authenticator = Tesla::BearerTokenAuthenticator.new(access_token: TEST_ACCESS_TOKEN)
      request = builder.build(http_method: :get, uri:, authenticator:, headers: {"Authorization" => "Bearer PARTNER"})

      expect(request["Authorization"]).to eq("Bearer PARTNER")
    end

    it "sets a JSON content type, which the Fleet API requires of every request" do
      expect(builder.build(http_method: :get, uri:)["Content-Type"]).to eq("application/json")
    end

    it "lets custom headers override the content type" do
      request = builder.build(http_method: :post, uri:, headers: {"Content-Type" => "application/x-www-form-urlencoded"})

      expect(request["Content-Type"]).to eq("application/x-www-form-urlencoded")
    end

    context "without a body" do
      it "does not set a body" do
        expect(builder.build(http_method: :post, uri:).body).to be_nil
      end
    end

    context "with a Hash body" do
      it "sends the body as JSON" do
        expect(builder.build(http_method: :post, uri:, body: {percent: 80}).body).to eq('{"percent":80}')
      end

      it "sends an empty body as an empty JSON object" do
        expect(builder.build(http_method: :post, uri:, body: {}).body).to eq("{}")
      end
    end

    context "with an Array body" do
      it "sends the body as JSON" do
        expect(builder.build(http_method: :post, uri:, body: [1, "two"]).body).to eq('[1,"two"]')
      end
    end

    context "with a String body" do
      it "sends the body as it is" do
        expect(builder.build(http_method: :post, uri:, body: "grant_type=refresh_token").body).to eq("grant_type=refresh_token")
      end
    end
  end
end
