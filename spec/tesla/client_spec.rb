# frozen_string_literal: true

RSpec.describe Tesla::Client do
  subject(:client) { described_class.new(access_token: TEST_ACCESS_TOKEN) }

  let(:path) { "/api/1/vehicles" }
  let(:refreshing_client) do
    described_class.new(access_token: TEST_ACCESS_TOKEN, refresh_token: TEST_REFRESH_TOKEN, client_id: TEST_CLIENT_ID)
  end

  it "includes the API" do
    expect(client).to be_a(Tesla::API)
  end

  it "keeps the methods of Forwardable, which it delegates with, private" do
    expect(Forwardable.instance_methods.select { |method| described_class.respond_to?(method) }).to be_empty
  end

  describe ".new" do
    it "returns the client without a block" do
      expect(described_class.new).to be_an_instance_of(described_class)
    end

    it "passes the options to the client" do
      expect(described_class.new(access_token: TEST_ACCESS_TOKEN).access_token).to eq(TEST_ACCESS_TOKEN)
    end

    it "yields the client to a block" do
      expect { |block| described_class.new(&block) }.to yield_with_args(an_instance_of(described_class))
    end

    it "passes the options to the client it yields" do
      expect(described_class.new(access_token: TEST_ACCESS_TOKEN, &:access_token)).to eq(TEST_ACCESS_TOKEN)
    end

    it "returns what the block returns" do
      expect(described_class.new { :done }).to eq(:done)
    end

    it "closes the client once the block is done with it" do
      closed = described_class.new do |client|
        allow(client).to receive(:close)
        client
      end

      expect(closed).to have_received(:close)
    end

    it "does not close the client before the block is done with it" do
      described_class.new do |client|
        allow(client).to receive(:close)

        expect(client).not_to have_received(:close)
      end
    end

    it "closes the client when the block raises" do
      connection = instance_double(Tesla::Connection, close: nil)
      allow(Tesla::Connection).to receive(:new).and_return(connection)
      described_class.new { raise "failed" }
    rescue RuntimeError
      expect(connection).to have_received(:close)
    end
  end

  describe "#close" do
    it "returns the client" do
      expect(client.close).to equal(client)
    end

    it "closes the connections the client keeps open" do
      connection = client.send(:connection)
      allow(connection).to receive(:close)
      client.close

      expect(connection).to have_received(:close)
    end
  end

  describe "#initialize" do
    context "with a global configuration" do
      let(:refresh) { proc {} }

      before do
        Tesla.configure do |config|
          config.host, config.access_token, config.refresh_token = Tesla::Configuration::EUROPE_HOST, "ACCESS", "REFRESH"
          config.client_id, config.client_secret, config.redirect_uri = "ID", "SECRET", TEST_REDIRECT_URI
          config.audience, config.authorization_endpoint, config.token_endpoint = "AUDIENCE", "AUTHORIZE", "TOKEN"
          config.on_token_refresh = refresh
          config.user_agent, config.open_timeout, config.read_timeout, config.write_timeout = "Agent", 1, 2, 3
          config.keep_alive_timeout, config.debug_output, config.max_redirects = 6, $stderr, 7
          config.proxy_url, config.ca_file = "http://proxy.example.com:8080", certificate_path("ca.pem")
          config.max_retries, config.max_retry_delay = 4, 5
        end
      end

      it "defaults the host and the credentials to it" do
        expect(described_class.new).to have_attributes(host: Tesla::Configuration::EUROPE_HOST, access_token: "ACCESS",
          refresh_token: "REFRESH", client_id: "ID", client_secret: "SECRET", redirect_uri: TEST_REDIRECT_URI)
      end

      it "defaults the endpoints tokens are asked for at to it" do
        expect(described_class.new).to have_attributes(audience: "AUDIENCE", authorization_endpoint: "AUTHORIZE",
          token_endpoint: "TOKEN", on_token_refresh: refresh)
      end

      it "defaults the connection options to it" do
        expect(described_class.new).to have_attributes(user_agent: "Agent", open_timeout: 1, read_timeout: 2,
          write_timeout: 3, proxy_url: "http://proxy.example.com:8080", ca_file: certificate_path("ca.pem"),
          max_retries: 4, max_retry_delay: 5)
      end

      it "defaults the keep-alive timeout, the debug output, and the maximum redirects to it" do
        expect(described_class.new).to have_attributes(keep_alive_timeout: 6, debug_output: $stderr, max_redirects: 7)
      end
    end

    it "sets the keep-alive timeout, the debug output, and the maximum redirects it is given" do
      client = described_class.new(keep_alive_timeout: 6, debug_output: $stderr, max_redirects: 7)

      expect(client).to have_attributes(keep_alive_timeout: 6, debug_output: $stderr, max_redirects: 7)
    end

    it "follows redirects on the connection of the client, with its request builder" do
      expect(client.send(:redirect_handler)).to have_attributes(connection: equal(client.send(:connection)),
        request_builder: equal(client.send(:request_builder)))
    end

    it "sets the host and the credentials it is given" do
      client = described_class.new(host: "https://localhost:4443", access_token: "ACCESS", refresh_token: "REFRESH",
        client_id: "ID", client_secret: "SECRET", redirect_uri: TEST_REDIRECT_URI)

      expect(client).to have_attributes(host: "https://localhost:4443", access_token: "ACCESS", refresh_token: "REFRESH",
        client_id: "ID", client_secret: "SECRET", redirect_uri: TEST_REDIRECT_URI)
    end

    it "sets the endpoints tokens are asked for at" do
      refresh = proc {}
      client = described_class.new(audience: "AUDIENCE", authorization_endpoint: "AUTHORIZE", token_endpoint: "TOKEN",
        on_token_refresh: refresh)

      expect(client).to have_attributes(audience: "AUDIENCE", authorization_endpoint: "AUTHORIZE", token_endpoint: "TOKEN",
        on_token_refresh: refresh)
    end

    it "sets the connection options it is given" do
      client = described_class.new(user_agent: "Agent", open_timeout: 1, read_timeout: 2, write_timeout: 3,
        proxy_url: "http://proxy.example.com:8080", ca_file: certificate_path("ca.pem"), max_retries: 4, max_retry_delay: 5)

      expect(client).to have_attributes(user_agent: "Agent", open_timeout: 1, read_timeout: 2, write_timeout: 3,
        proxy_url: "http://proxy.example.com:8080", ca_file: certificate_path("ca.pem"), max_retries: 4, max_retry_delay: 5)
    end

    it "builds a client that reads the responses of its requests" do
      stub_get(path).to_return(body: "body")

      expect(described_class.new.get(path)).to eq("body")
    end

    it "raises for a host that is not a URL" do
      expect { described_class.new(host: "localhost") }.to raise_error(ArgumentError, "Invalid host: localhost")
    end

    it "raises for a host that carries a user and password, without showing them" do
      expect { described_class.new(host: "https://user:secret@localhost:4443") }
        .to raise_error(ArgumentError, "Invalid host: https://localhost:4443 carries a user and password, which are not sent")
    end
  end

  describe "#host=" do
    it "assigns the host" do
      client.host = Tesla::Configuration::EUROPE_HOST

      expect(client.host).to eq(Tesla::Configuration::EUROPE_HOST)
    end

    it "raises for a host that is not a URL" do
      expect { client.host = "localhost" }.to raise_error(ArgumentError, "Invalid host: localhost")
    end

    it "leaves the host as it was after a host it refuses" do
      client.host = "localhost"
    rescue ArgumentError
      expect(client.host).to eq(TEST_HOST)
    end
  end

  describe "#max_redirects=" do
    it "assigns the maximum redirects of the redirect handler" do
      client.max_redirects = 7

      expect([client.max_redirects, client.send(:redirect_handler).max_redirects]).to eq([7, 7])
    end
  end

  describe "#debug_output=" do
    it "assigns the debug output of the connection" do
      client.debug_output = $stderr

      expect([client.debug_output, client.send(:connection).debug_output]).to eq([$stderr, $stderr])
    end
  end

  %i[open_timeout read_timeout write_timeout keep_alive_timeout proxy_url ca_file].each do |setting|
    describe "##{setting}=" do
      it "assigns the #{setting} of the connection" do
        value = {proxy_url: "http://proxy.example.com:8080", ca_file: certificate_path("ca.pem")}.fetch(setting, 7)
        client.public_send(:"#{setting}=", value)

        expect([client.public_send(setting), client.send(:connection).public_send(setting)]).to eq([value, value])
      end
    end
  end

  %i[max_retries max_retry_delay].each do |setting|
    describe "##{setting}=" do
      it "assigns the #{setting} of the retry handler" do
        client.public_send(:"#{setting}=", 7)

        expect([client.public_send(setting), client.send(:retry_handler).public_send(setting)]).to eq([7, 7])
      end
    end
  end

  describe "#user_agent=" do
    it "assigns the user agent of the request builder" do
      client.user_agent = "Agent"

      expect([client.user_agent, client.send(:request_builder).user_agent]).to eq(%w[Agent Agent])
    end
  end

  describe "#inspect" do
    it "shows the host" do
      expect(client.inspect).to eq('#<Tesla::Client host="https://fleet-api.prd.na.vn.cloud.tesla.com">')
    end

    it "leaves out the credentials" do
      expect(refreshing_client.inspect).not_to include(TEST_ACCESS_TOKEN, TEST_REFRESH_TOKEN, TEST_CLIENT_ID)
    end
  end

  %i[get delete].each do |http_method|
    describe "##{http_method}" do
      before { stub_request(http_method, tesla_url(path)).with(query: hash_including({})).to_return(body: "body") }

      it "sends a #{http_method.upcase} request to the path on the host" do
        client.public_send(http_method, path)

        expect(a_request(http_method, tesla_url(path))).to have_been_made
      end

      it "returns the response body" do
        expect(client.public_send(http_method, path)).to eq("body")
      end

      it "sends the query parameters" do
        client.public_send(http_method, path, {page: 2})

        expect(a_request(http_method, tesla_url("#{path}?page=2"))).to have_been_made
      end

      it "sends no body" do
        client.public_send(http_method, path)

        expect(a_request(http_method, tesla_url(path)).with(body: nil)).to have_been_made
      end

      it "sends the headers it is given" do
        client.public_send(http_method, path, headers: {"X-Custom" => "value"})

        expect(a_request(http_method, tesla_url(path)).with(headers: {"X-Custom" => "value"})).to have_been_made
      end

      it "authorizes the request with the access token" do
        client.public_send(http_method, path)

        expect(a_request(http_method, tesla_url(path)).with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"}))
          .to have_been_made
      end
    end
  end

  %i[post put patch].each do |http_method|
    describe "##{http_method}" do
      before { stub_request(http_method, tesla_url(path)).to_return(body: "body") }

      it "sends a #{http_method.upcase} request to the path on the host" do
        client.public_send(http_method, path)

        expect(a_request(http_method, tesla_url(path))).to have_been_made
      end

      it "returns the response body" do
        expect(client.public_send(http_method, path)).to eq("body")
      end

      it "sends an empty JSON object by default" do
        client.public_send(http_method, path)

        expect(a_request(http_method, tesla_url(path)).with(body: "{}")).to have_been_made
      end

      it "sends the body as JSON" do
        client.public_send(http_method, path, {percent: 80})

        expect(a_request(http_method, tesla_url(path))
          .with(body: '{"percent":80}', headers: {"Content-Type" => "application/json"})).to have_been_made
      end

      it "sends no query" do
        client.public_send(http_method, path, {percent: 80})

        expect(a_request(http_method, tesla_url(path)).with(query: {})).to have_been_made
      end

      it "sends the headers it is given" do
        client.public_send(http_method, path, headers: {"X-Custom" => "value"})

        expect(a_request(http_method, tesla_url(path)).with(headers: {"X-Custom" => "value"})).to have_been_made
      end
    end
  end

  describe "#execute_request" do
    it "sends the request without an Authorization header when the client has no access token" do
      stub_get(path)
      described_class.new.get(path)

      expect(a_get(path).with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "sends the user agent of the client" do
      stub_get(path)
      client.user_agent = "Agent"
      client.get(path)

      expect(a_get(path).with(headers: {"User-Agent" => "Agent"})).to have_been_made
    end

    it "sends the query parameters of the request" do
      stub_get("#{path}?page=2")
      client.get(path, {page: 2})

      expect(a_get("#{path}?page=2")).to have_been_made
    end

    it "sends the body of the request" do
      stub_post(path)
      client.post(path, {percent: 80})

      expect(a_post(path).with(body: '{"percent":80}')).to have_been_made
    end

    it "sends the headers of the request" do
      stub_get(path)
      client.get(path, headers: {"X-Custom" => "value"})

      expect(a_get(path).with(headers: {"X-Custom" => "value"})).to have_been_made
    end

    it "authorizes the request with the access token of the client" do
      stub_get(path)
      client.get(path)

      expect(a_get(path).with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"})).to have_been_made
    end

    it "returns the response body" do
      stub_get(path).to_return(body: "body")

      expect(client.get(path)).to eq("body")
    end

    it "raises the error of an unsuccessful response" do
      stub_get(path).to_return(status: 408, body: '{"response":null,"error":"vehicle unavailable","error_description":""}')

      expect { client.get(path) }.to raise_error(Tesla::RequestTimeout, "vehicle unavailable")
    end

    it "raises a NetworkError for a request the network lost" do
      client.max_retries = 0
      stub_get(path).to_raise(Errno::ECONNRESET)

      expect { client.get(path) }.to raise_error(Tesla::NetworkError)
    end

    it "keeps the path prefix of the host" do
      stub_request(:get, "https://tesla.example.com/fleet/api/1/vehicles")
      described_class.new(host: "https://tesla.example.com/fleet/").get(path)

      expect(a_request(:get, "https://tesla.example.com/fleet/api/1/vehicles")).to have_been_made
    end

    it "takes a path without a leading slash" do
      stub_get(path)
      client.get("api/1/vehicles")

      expect(a_get(path)).to have_been_made
    end

    it "takes a path that is a URL on the host" do
      stub_get(path)
      client.get(tesla_url(path))

      expect(a_get(path)).to have_been_made
    end

    it "refuses a path that is a URL of another host, which would be sent the access token" do
      expect { client.get("https://example.com/api/1/vehicles") }
        .to raise_error(ArgumentError, "Path is not on #{TEST_HOST}: https://example.com/api/1/vehicles")
    end

    it "refuses a path that climbs out of the prefix of the host" do
      expect { described_class.new(host: "https://tesla.example.com/fleet").get("../api/1/vehicles") }
        .to raise_error(ArgumentError, "Path is not on https://tesla.example.com/fleet: ../api/1/vehicles")
    end

    context "when a request is redirected" do
      let(:client) { described_class.new(access_token: TEST_ACCESS_TOKEN, max_retries: 1, max_redirects: 2) }

      before { allow(client.send(:retry_handler)).to receive(:sleep) }

      it "follows the redirect" do
        stub_get(path).to_return(status: 302, headers: {"Location" => "/api/1/new"})
        stub_get("/api/1/new").to_return(body: "body")

        expect(client.get(path)).to eq("body")
      end

      it "follows a redirect on the host with the access token" do
        stub_get(path).to_return(status: 302, headers: {"Location" => "/api/1/new"})
        stub_get("/api/1/new")
        client.get(path)

        expect(a_get("/api/1/new").with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"})).to have_been_made
      end

      it "follows a redirect that keeps the method with the body and the headers of the request" do
        stub_post(path).to_return(status: 307, headers: {"Location" => "/api/1/new"})
        stub_post("/api/1/new")
        client.post(path, {percent: 80}, headers: {"X-Custom" => "value"})

        expect(a_post("/api/1/new").with(body: '{"percent":80}', headers: {"X-Custom" => "value"})).to have_been_made
      end

      it "follows a redirect to another host without the access token" do
        stub_get(path).to_return(status: 302, headers: {"Location" => "https://example.com/new"})
        stub_request(:get, "https://example.com/new")
        client.get(path)

        expect(a_request(:get, "https://example.com/new").with { |request| !request.headers.key?("Authorization") })
          .to have_been_made
      end

      it "raises TooManyRedirects once it has followed as many as it may" do
        stub_get(path).to_return(status: 302, headers: {"Location" => path})

        expect { client.get(path) }.to raise_error(Tesla::TooManyRedirects)
      end

      it "follows the redirect again from the start when the request is sent again" do
        stub_get(path).to_return(status: 302, headers: {"Location" => "/api/1/new"})
        stub_get("/api/1/new").to_return({status: 503}, {body: "body"})
        client.get(path)

        expect(a_get(path)).to have_been_made.twice
      end
    end

    context "when a request is turned away" do
      before { allow(client.send(:retry_handler)).to receive(:sleep) }

      it "sends a request a rate limiter turned away again" do
        stub_post(path).to_return({status: 429, headers: {"Retry-After" => "1"}}, {body: "body"})

        expect(client.post(path)).to eq("body")
      end

      it "sends a request that asks for something again when it goes unanswered" do
        stub_get(path).to_return({status: 503}, {body: "body"})

        expect(client.get(path)).to eq("body")
      end

      it "does not send a request that asks a vehicle to do something again when it goes unanswered" do
        stub_post(path).to_return({status: 503}, {body: "body"})

        expect { client.post(path) }.to raise_error(Tesla::ServiceUnavailable)
      end
    end

    context "when the access token is no longer good" do
      subject(:client) { refreshing_client }

      before do
        stub_token
        stub_get(path).with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"}).to_return(status: 401)
        stub_get(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"}).to_return(body: "body")
      end

      it "refreshes the access token and sends the request again" do
        expect(client.get(path)).to eq("body")
      end

      it "refreshes the access token once" do
        client.get(path)

        expect(a_token_request).to have_been_made.once
      end

      it "sends the request again as it was" do
        stub_post(path).with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"}).to_return(status: 401)
        stub_post(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"}).to_return(body: "body")
        client.post(path, {percent: 80}, headers: {"X-Custom" => "value"})

        expect(a_post(path).with(body: {percent: 80}, headers: {"X-Custom" => "value"})).to have_been_made.twice
      end

      it "sends the next request with the access token it was answered with" do
        client.get(path)
        client.get(path)

        expect(a_get(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"})).to have_been_made.twice
      end

      it "raises when the new access token is turned away too" do
        stub_get(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"}).to_return(status: 401)

        expect { client.get(path) }.to raise_error(Tesla::Unauthorized)
      end

      it "sends the request no more than twice" do
        stub_get(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"}).to_return(status: 401)
        client.get(path)
      rescue Tesla::Unauthorized
        expect(a_get(path)).to have_been_made.twice
      end

      it "raises without refreshing when the client has no refresh token" do
        client.refresh_token = nil

        expect { client.get(path) }.to raise_error(Tesla::Unauthorized)
      end

      it "sends the request once when the client has no refresh token" do
        client.refresh_token = nil
        client.get(path)
      rescue Tesla::Unauthorized
        expect(a_get(path)).to have_been_made.once
      end

      it "does not refresh the access token for another error" do
        stub_get(path).with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"}).to_return(status: 403)
        client.get(path)
      rescue Tesla::Forbidden
        expect(a_token_request).not_to have_been_made
      end
    end

    context "when the client has a refresh token and no access token" do
      subject(:client) { described_class.new(refresh_token: TEST_REFRESH_TOKEN, client_id: TEST_CLIENT_ID) }

      before do
        stub_token
        stub_get(path).to_return(body: "body")
      end

      it "asks for an access token before its first request" do
        client.get(path)

        expect(a_get(path).with(headers: {"Authorization" => "Bearer NEW_ACCESS_TOKEN"})).to have_been_made.once
      end
    end
  end
end
