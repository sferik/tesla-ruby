# frozen_string_literal: true

RSpec.describe Tesla do
  it "extends Tesla::Configuration" do
    expect(described_class).to be_a(Tesla::Configuration)
  end

  it "keeps the methods of SingleForwardable, which it delegates with, private" do
    expect(SingleForwardable.instance_methods.select { |method| described_class.respond_to?(method) }).to be_empty
  end

  it "delegates every endpoint of the API" do
    expect(Tesla::API.public_instance_methods.reject { |method| described_class.respond_to?(method) }).to be_empty
  end

  it "keeps the constants it builds its client with private" do
    expect(described_class.constants).not_to include(:CLIENT_MUTEX, :CLIENT_SETTINGS, :APPLIED_SETTINGS)
  end

  describe "::VERSION" do
    it "is a String" do
      expect(Tesla::VERSION).to be_a(String)
    end

    it "is a valid gem version" do
      expect(Gem::Version.correct?(Tesla::VERSION)).to be(true)
    end
  end

  describe ".new" do
    it "returns a Tesla::Client" do
      expect(described_class.new).to be_an_instance_of(Tesla::Client)
    end

    it "passes options to the client" do
      client = described_class.new(access_token: TEST_ACCESS_TOKEN, host: "http://example.com", max_retries: 3)

      expect(client).to have_attributes(access_token: TEST_ACCESS_TOKEN, host: "http://example.com", max_retries: 3)
    end

    it "passes a block to the client, which closes it once the block is done with it" do
      closed = described_class.new(access_token: TEST_ACCESS_TOKEN) do |client|
        allow(client).to receive(:close)
        client
      end

      expect(closed).to have_received(:close)
    end
  end

  describe ".client" do
    it "returns a Tesla::Client" do
      expect(described_class.client).to be_an_instance_of(Tesla::Client)
    end

    it "builds the client from the global configuration" do
      described_class.configure do |config|
        config.access_token, config.host, config.max_retries = TEST_ACCESS_TOKEN, "http://example.com", 3
      end

      expect(described_class.client).to have_attributes(access_token: TEST_ACCESS_TOKEN, host: "http://example.com",
        max_retries: 3)
    end

    it "returns the same client while the configuration is unchanged" do
      expect(described_class.client).to equal(described_class.client)
    end

    {host: "http://example.com", access_token: "ACCESS", refresh_token: "REFRESH", client_id: "ID",
     client_secret: "SECRET"}.each do |option, value|
      it "builds a new client when #{option} changes" do
        client = described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client).not_to equal(client)
      end

      it "gives the new client the #{option}" do
        described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client.public_send(option)).to eq(value)
      end
    end

    it "closes the connections of the client it replaces" do
      client = described_class.client
      allow(client).to receive(:close)
      described_class.host = "http://example.com"
      described_class.client

      expect(client).to have_received(:close)
    end

    context "when another client cannot be built from the configuration" do
      let(:client) { described_class.client }

      before do
        allow(client).to receive(:close)
        described_class.host = "http://example.com"
        allow(Tesla::Client).to receive(:new).and_raise(ArgumentError)
      end

      it "keeps the connections of the client it has open" do
        described_class.client
      rescue ArgumentError
        expect(client).not_to have_received(:close)
      end
    end

    it "builds a new client when a credential the environment carries changes" do
      client = described_class.client

      with_env("TESLA_ACCESS_TOKEN" => "FROM_ENVIRONMENT") { expect(described_class.client).not_to equal(client) }
    end

    {redirect_uri: TEST_REDIRECT_URI, audience: "AUDIENCE", authorization_endpoint: "AUTHORIZE", token_endpoint: "TOKEN",
     on_token_refresh: proc {}, user_agent: "Agent", open_timeout: 1, read_timeout: 2, write_timeout: 3,
     keep_alive_timeout: 6, debug_output: StringIO.new, max_redirects: 7, proxy_url: "http://proxy.example.com:8080", max_retries: 4, max_retry_delay: 5}.each do |option, value|
      it "applies a changed #{option} to the client it has" do
        client = described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client).to equal(client).and have_attributes(option => value)
      end
    end

    it "applies a changed ca_file to the client it has" do
      client = described_class.client
      described_class.ca_file = certificate_path("ca.pem")

      expect(described_class.client).to equal(client).and have_attributes(ca_file: certificate_path("ca.pem"))
    end

    it "keeps the tokens the client refreshed when a setting that is applied to it changes" do
      described_class.configure { |config| config.refresh_token, config.client_id = TEST_REFRESH_TOKEN, TEST_CLIENT_ID }
      stub_token
      described_class.refresh_access_token
      described_class.read_timeout = 5

      expect(described_class.client).to have_attributes(refresh_token: "NEW_REFRESH_TOKEN", read_timeout: 5)
    end

    it "does not apply the settings again while they are unchanged" do
      client = described_class.client
      client.read_timeout = 5

      expect(described_class.client.read_timeout).to eq(5)
    end

    it "builds one client for the threads that ask for it at once" do
      clients = Array.new(8) { Thread.new { described_class.client } }.map(&:value)

      expect(clients.uniq(&:object_id).size).to eq(1)
    end

    it "builds the client while it holds the mutex, so that no other thread builds one too" do
      mutex = described_class.const_get(:CLIENT_MUTEX)
      allow(described_class).to receive(:new).and_wrap_original { |original| original.call.tap { expect(mutex).to be_locked } }
      described_class.reset

      described_class.client
    end
  end

  describe ".reset" do
    it "returns the module" do
      expect(described_class.reset).to equal(described_class)
    end

    it "resets the configuration" do
      described_class.max_retries = 5

      expect(described_class.reset.max_retries).to eq(Tesla::RetryHandler::DEFAULT_MAX_RETRIES)
    end

    it "closes the connections of the client" do
      client = described_class.client
      allow(client).to receive(:close)
      described_class.reset

      expect(client).to have_received(:close)
    end

    it "resets without a client to close" do
      described_class.reset

      expect(described_class.reset).to equal(described_class)
    end

    it "forgets the client, and with it the tokens it refreshed" do
      client = described_class.client
      described_class.reset

      expect(described_class.client).not_to equal(client)
    end

    it "resets while it holds the mutex, so that no thread is given a client built from half of each configuration" do
      mutex = described_class.const_get(:CLIENT_MUTEX)
      described_class.user_agent = "Agent"
      allow(described_class).to receive(:user_agent=).and_wrap_original { |original, value| original.call(value) if mutex.locked? }

      expect(described_class.reset.user_agent).to eq(Tesla::Configuration::DEFAULT_USER_AGENT)
    end
  end

  describe "the endpoints of the API" do
    it "are sent with the client of the module" do
      described_class.access_token = TEST_ACCESS_TOKEN
      stub_command("actuate_trunk")
      described_class.actuate_trunk(TEST_VIN)

      expect(a_command("actuate_trunk").with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"})).to have_been_made
    end
  end
end
