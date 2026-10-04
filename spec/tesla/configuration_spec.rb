# frozen_string_literal: true

RSpec.describe Tesla::Configuration do
  subject(:configuration) { Module.new.extend(described_class) }

  describe "::NORTH_AMERICA_HOST" do
    it "is the host of the Fleet API for North America" do
      expect(described_class::NORTH_AMERICA_HOST).to eq("https://fleet-api.prd.na.vn.cloud.tesla.com")
    end
  end

  describe "::EUROPE_HOST" do
    it "is the host of the Fleet API for Europe" do
      expect(described_class::EUROPE_HOST).to eq("https://fleet-api.prd.eu.vn.cloud.tesla.com")
    end
  end

  describe "::CHINA_HOST" do
    it "is the host of the Fleet API for China" do
      expect(described_class::CHINA_HOST).to eq("https://fleet-api.prd.cn.vn.cloud.tesla.cn")
    end
  end

  describe "::DEFAULT_HOST" do
    it "is the host of the Fleet API for North America" do
      expect(described_class::DEFAULT_HOST).to equal(described_class::NORTH_AMERICA_HOST)
    end
  end

  describe "::DEFAULT_AUTHORIZATION_ENDPOINT" do
    it "is the authorization endpoint of Tesla's authorization server" do
      expect(described_class::DEFAULT_AUTHORIZATION_ENDPOINT).to eq("https://auth.tesla.com/oauth2/v3/authorize")
    end
  end

  describe "::DEFAULT_TOKEN_ENDPOINT" do
    it "is the token endpoint of the Fleet API" do
      expect(described_class::DEFAULT_TOKEN_ENDPOINT).to eq("https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token")
    end
  end

  describe "::DEFAULT_USER_AGENT" do
    it "is the user agent of the request builder" do
      expect(described_class::DEFAULT_USER_AGENT).to equal(Tesla::RequestBuilder::DEFAULT_USER_AGENT)
    end
  end

  describe "::ENVIRONMENT" do
    it "is private" do
      expect { described_class::ENVIRONMENT }.to raise_error(NameError, /private constant/)
    end
  end

  describe ".extended" do
    it "resets the configuration of whatever extends it" do
      expect(configuration.host).to eq(described_class::DEFAULT_HOST)
    end
  end

  describe "#host=" do
    it "assigns the host" do
      configuration.host = described_class::EUROPE_HOST

      expect(configuration.host).to eq(described_class::EUROPE_HOST)
    end

    it "raises for a host that is not a URL" do
      expect { configuration.host = "fleet-api" }.to raise_error(ArgumentError, "Invalid host: fleet-api")
    end

    it "raises for a host that cannot be read as a URL" do
      expect { configuration.host = "https://tesla example.com" }
        .to raise_error(ArgumentError, "Invalid host: https://tesla example.com")
    end

    it "raises for a host that is not a String" do
      expect { configuration.host = nil }.to raise_error(ArgumentError, "Invalid host: ")
    end

    it "leaves the host as it was after a host it refuses" do
      configuration.host = "fleet-api"
    rescue ArgumentError
      expect(configuration.host).to eq(described_class::DEFAULT_HOST)
    end
  end

  describe "#default_host" do
    it "is the host of the Fleet API for North America" do
      expect(configuration.default_host).to eq(described_class::NORTH_AMERICA_HOST)
    end

    it "is the TESLA_HOST environment variable when it is set" do
      with_env("TESLA_HOST" => "https://localhost:4443") { expect(configuration.default_host).to eq("https://localhost:4443") }
    end
  end

  {access_token: "TESLA_ACCESS_TOKEN", refresh_token: "TESLA_REFRESH_TOKEN", client_id: "TESLA_CLIENT_ID",
   client_secret: "TESLA_CLIENT_SECRET", redirect_uri: "TESLA_REDIRECT_URI"}.each do |setting, variable|
    describe "##{setting}" do
      it "is nil by default" do
        expect(configuration.public_send(setting)).to be_nil
      end

      it "falls back to the #{variable} environment variable" do
        with_env(variable => "FROM_ENVIRONMENT") { expect(configuration.public_send(setting)).to eq("FROM_ENVIRONMENT") }
      end

      it "is the value it was assigned rather than the environment variable" do
        configuration.public_send(:"#{setting}=", "ASSIGNED")

        with_env(variable => "FROM_ENVIRONMENT") { expect(configuration.public_send(setting)).to eq("ASSIGNED") }
      end

      it "falls back to the environment variable again once the configuration is reset" do
        configuration.public_send(:"#{setting}=", "ASSIGNED")
        configuration.reset

        with_env(variable => "FROM_ENVIRONMENT") { expect(configuration.public_send(setting)).to eq("FROM_ENVIRONMENT") }
      end
    end
  end

  describe "#audience" do
    it "is nil by default, for the host of the client" do
      expect(configuration.audience).to be_nil
    end

    it "is the audience it was assigned" do
      configuration.audience = described_class::EUROPE_HOST

      expect(configuration.audience).to eq(described_class::EUROPE_HOST)
    end
  end

  describe "#authorization_endpoint" do
    it "defaults to the authorization endpoint of Tesla's authorization server" do
      expect(configuration.authorization_endpoint).to eq(described_class::DEFAULT_AUTHORIZATION_ENDPOINT)
    end
  end

  describe "#token_endpoint" do
    it "defaults to the token endpoint of the Fleet API" do
      expect(configuration.token_endpoint).to eq(described_class::DEFAULT_TOKEN_ENDPOINT)
    end
  end

  describe "#on_token_refresh" do
    it "is nil by default" do
      expect(configuration.on_token_refresh).to be_nil
    end
  end

  describe "#user_agent" do
    it "defaults to the default user agent" do
      expect(configuration.user_agent).to eq(described_class::DEFAULT_USER_AGENT)
    end
  end

  {open_timeout: Tesla::Connection::DEFAULT_OPEN_TIMEOUT, read_timeout: Tesla::Connection::DEFAULT_READ_TIMEOUT,
   write_timeout: Tesla::Connection::DEFAULT_WRITE_TIMEOUT,
   keep_alive_timeout: Tesla::Connection::DEFAULT_KEEP_ALIVE_TIMEOUT,
   max_retry_delay: Tesla::RetryHandler::DEFAULT_MAX_RETRY_DELAY}.each do |setting, default|
    describe "##{setting}" do
      it "defaults to #{default} seconds" do
        expect(configuration.public_send(setting)).to eq(default)
      end

      it "is the number of seconds it was assigned" do
        configuration.public_send(:"#{setting}=", 0.5)

        expect(configuration.public_send(setting)).to eq(0.5)
      end

      it "raises for a negative number of seconds" do
        expect { configuration.public_send(:"#{setting}=", -1) }.to raise_error(ArgumentError, "Invalid #{setting}: -1")
      end
    end
  end

  describe "#debug_output" do
    it "is nil by default" do
      expect(configuration.debug_output).to be_nil
    end

    it "is the IO it was assigned" do
      configuration.debug_output = $stderr

      expect(configuration.debug_output).to equal($stderr)
    end
  end

  describe "#max_redirects" do
    it "defaults to the default of the redirect handler" do
      expect(configuration.max_redirects).to eq(Tesla::RedirectHandler::DEFAULT_MAX_REDIRECTS)
    end

    it "is the number of times it was assigned" do
      configuration.max_redirects = 0

      expect(configuration.max_redirects).to eq(0)
    end

    it "raises for a number that is not whole" do
      expect { configuration.max_redirects = 1.5 }.to raise_error(ArgumentError, "Invalid max_redirects: 1.5")
    end
  end

  describe "#max_retries" do
    it "defaults to the default of the retry handler" do
      expect(configuration.max_retries).to eq(Tesla::RetryHandler::DEFAULT_MAX_RETRIES)
    end

    it "is the number of times it was assigned" do
      configuration.max_retries = 0

      expect(configuration.max_retries).to eq(0)
    end

    it "raises for a number that is not whole" do
      expect { configuration.max_retries = 1.5 }.to raise_error(ArgumentError, "Invalid max_retries: 1.5")
    end
  end

  describe "#proxy_url=" do
    it "is nil by default" do
      expect(configuration.proxy_url).to be_nil
    end

    it "assigns the proxy URL" do
      configuration.proxy_url = "http://proxy.example.com:8080"

      expect(configuration.proxy_url).to eq("http://proxy.example.com:8080")
    end

    it "raises for a proxy URL that is not an HTTP URL" do
      expect { configuration.proxy_url = "ftp://user:secret@proxy.example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: ftp://proxy.example.com/")
    end

    it "leaves the proxy URL as it was after a URL it refuses" do
      configuration.proxy_url = "http://proxy.example.com:8080"
      configuration.proxy_url = "ftp://proxy.example.com/"
    rescue ArgumentError
      expect(configuration.proxy_url).to eq("http://proxy.example.com:8080")
    end
  end

  describe "#ca_file=" do
    it "is nil by default" do
      expect(configuration.ca_file).to be_nil
    end

    it "assigns the path of a file" do
      configuration.ca_file = certificate_path("ca.pem")

      expect(configuration.ca_file).to eq(certificate_path("ca.pem"))
    end

    it "raises for a path that names nothing" do
      expect { configuration.ca_file = certificate_path("missing.pem") }.to raise_error(ArgumentError, /\AInvalid CA file: /)
    end
  end

  describe "#configure" do
    it "yields the configuration" do
      expect { |block| configuration.configure(&block) }.to yield_with_args(configuration)
    end

    it "returns the configuration" do
      expect(configuration.configure { |config| config.max_retries = 0 }).to equal(configuration)
    end
  end

  describe "#reset" do
    before do
      configuration.configure do |config|
        config.host = described_class::EUROPE_HOST
        config.audience = described_class::EUROPE_HOST
        config.authorization_endpoint = "https://auth.tesla.cn/oauth2/v3/authorize"
        config.token_endpoint = "https://auth.tesla.cn/oauth2/v3/token"
        config.on_token_refresh = proc {}
        config.user_agent = "Custom User Agent"
        config.open_timeout = 1
        config.read_timeout = 2
        config.write_timeout = 3
        config.keep_alive_timeout = 6
        config.debug_output = $stderr
        config.max_redirects = 7
        config.proxy_url = "http://proxy.example.com:8080"
        config.ca_file = certificate_path("ca.pem")
        config.max_retries = 4
        config.max_retry_delay = 5
      end
    end

    it "returns the configuration" do
      expect(configuration.reset).to equal(configuration)
    end

    it "resets the host" do
      expect(configuration.reset.host).to eq(described_class::DEFAULT_HOST)
    end

    it "resets the host to the TESLA_HOST environment variable when it is set" do
      with_env("TESLA_HOST" => "https://localhost:4443") { expect(configuration.reset.host).to eq("https://localhost:4443") }
    end

    it "takes a default host that is not a URL as it is, for a client to report" do
      with_env("TESLA_HOST" => "localhost") { expect(configuration.reset.host).to eq("localhost") }
    end

    it "resets the credentials and the endpoints tokens are asked for at" do
      expect(configuration.reset).to have_attributes(audience: nil, on_token_refresh: nil,
        authorization_endpoint: described_class::DEFAULT_AUTHORIZATION_ENDPOINT,
        token_endpoint: described_class::DEFAULT_TOKEN_ENDPOINT)
    end

    it "resets the user agent" do
      expect(configuration.reset.user_agent).to eq(described_class::DEFAULT_USER_AGENT)
    end

    it "resets the connection options" do
      expect(configuration.reset).to have_attributes(open_timeout: 60, read_timeout: 60, write_timeout: 60,
        keep_alive_timeout: 2, debug_output: nil, proxy_url: nil, ca_file: nil)
    end

    it "resets the redirect and retry options" do
      expect(configuration.reset).to have_attributes(max_redirects: 10, max_retries: 2, max_retry_delay: 60)
    end
  end
end
