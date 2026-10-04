# frozen_string_literal: true

RSpec.describe Tesla::RedirectHandler do
  subject(:handler) { described_class.new(connection:, request_builder:) }

  let(:connection) { Tesla::Connection.new }
  let(:request_builder) { Tesla::RequestBuilder.new }
  let(:request) { Net::HTTP::Get.new(URI("#{TEST_HOST}/old")) }
  let(:json_request) { request_builder.build(http_method: :post, uri: URI("#{TEST_HOST}/old"), body: json_body) }

  def redirect(code, location, klass: Net::HTTPFound)
    response = klass.new("1.1", code.to_s, "Redirect")
    response["Location"] = location
    response
  end

  def json_body
    {key: "value"}
  end

  describe "#initialize" do
    it "defaults the connection" do
      expect(described_class.new.connection).to be_an_instance_of(Tesla::Connection)
    end

    it "defaults the request builder" do
      expect(described_class.new.request_builder).to be_an_instance_of(Tesla::RequestBuilder)
    end

    it "defaults the maximum redirects" do
      expect(described_class.new.max_redirects).to eq(described_class::DEFAULT_MAX_REDIRECTS)
    end

    it "sets the connection" do
      expect(handler.connection).to equal(connection)
    end

    it "sets the request builder" do
      expect(handler.request_builder).to equal(request_builder)
    end

    it "sets the maximum redirects" do
      expect(described_class.new(max_redirects: 3).max_redirects).to eq(3)
    end
  end

  describe "#max_redirects=" do
    it "assigns a number of redirects" do
      handler.max_redirects = 3

      expect(handler.max_redirects).to eq(3)
    end

    it "raises for a negative number of redirects" do
      expect { handler.max_redirects = -1 }.to raise_error(ArgumentError, "Invalid max_redirects: -1")
    end

    it "raises for a number of redirects that is not whole" do
      expect { handler.max_redirects = 1.5 }.to raise_error(ArgumentError, "Invalid max_redirects: 1.5")
    end

    it "leaves the maximum as it was after a value it refuses" do
      handler.max_redirects = 3
      handler.max_redirects = -1
    rescue ArgumentError
      expect(handler.max_redirects).to eq(3)
    end

    it "refuses the maximum the handler is built with" do
      expect { described_class.new(max_redirects: -1) }.to raise_error(ArgumentError, "Invalid max_redirects: -1")
    end
  end

  describe "#handle" do
    it "returns a non-redirect response unchanged" do
      response = Net::HTTPOK.new("1.1", "200", "OK")

      expect(handler.handle(response:, request:)).to equal(response)
    end

    it "does not follow the Location header of a successful response" do
      response = Net::HTTPCreated.new("1.1", "201", "Created")
      response["Location"] = "#{TEST_HOST}/new"

      expect(handler.handle(response:, request:)).to equal(response)
    end

    it "follows an absolute redirect" do
      stub_request(:get, "https://bundler.fleet-api.prd.na.vn.cloud.tesla.com/new")
      handler.handle(response: redirect(302, "https://bundler.fleet-api.prd.na.vn.cloud.tesla.com/new"), request:)

      expect(a_request(:get, "https://bundler.fleet-api.prd.na.vn.cloud.tesla.com/new")).to have_been_made
    end

    it "follows a relative redirect" do
      stub_request(:get, "#{TEST_HOST}/new")
      handler.handle(response: redirect(302, "/new"), request:)

      expect(a_request(:get, "#{TEST_HOST}/new")).to have_been_made
    end

    it "returns the final response" do
      stub_request(:get, "#{TEST_HOST}/new").to_return(body: "final")

      expect(handler.handle(response: redirect(302, "/new"), request:).body).to eq("final")
    end

    it "follows multiple redirects" do
      stub_request(:get, "#{TEST_HOST}/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "#{TEST_HOST}/third")
      handler.handle(response: redirect(302, "/second"), request:)

      expect(a_request(:get, "#{TEST_HOST}/third")).to have_been_made
    end

    it "preserves authentication across redirects" do
      authenticator = Tesla::BearerTokenAuthenticator.new(access_token: TEST_ACCESS_TOKEN)
      stub_request(:get, "#{TEST_HOST}/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "#{TEST_HOST}/third")
      handler.handle(response: redirect(302, "/second"), request:, authenticator:)

      expect(a_request(:get, "#{TEST_HOST}/third").with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"})).to have_been_made
    end

    it "preserves the headers of the caller across redirects" do
      stub_request(:get, "#{TEST_HOST}/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "#{TEST_HOST}/third")
      handler.handle(response: redirect(302, "/second"), request:, headers: {"X-Trace-Id" => "abc123"})

      expect(a_request(:get, "#{TEST_HOST}/third")
        .with(headers: {"X-Trace-Id" => "abc123"})).to have_been_made
    end

    context "when a redirect leaves the origin" do
      let(:authenticator) { Tesla::BearerTokenAuthenticator.new(access_token: TEST_ACCESS_TOKEN) }

      def headers_sent_to(location, uri = location)
        stub_request(:get, uri)
        handler.handle(response: redirect(302, location), request:, authenticator:)
        headers = nil
        expect(a_request(:get, uri).with { |req| headers = req.headers }).to have_been_made
        headers
      end

      it "drops the credentials for another host" do
        expect(headers_sent_to("https://example.com/new").keys).not_to include("Authorization")
      end

      it "drops the credentials for another scheme" do
        expect(headers_sent_to("http://fleet-api.prd.na.vn.cloud.tesla.com/new").keys).not_to include("Authorization")
      end

      it "drops the credentials for another scheme on the same port" do
        expect(headers_sent_to("http://fleet-api.prd.na.vn.cloud.tesla.com:443/new").keys).not_to include("Authorization")
      end

      it "drops the credentials for another port" do
        expect(headers_sent_to("#{TEST_HOST}:8443/new").keys).not_to include("Authorization")
      end

      it "keeps the credentials for the same origin spelled in another case" do
        expect(headers_sent_to("HTTPS://Fleet-API.prd.na.vn.cloud.Tesla.com/new", "#{TEST_HOST}/new"))
          .to include("Authorization" => "Bearer #{TEST_ACCESS_TOKEN}")
      end

      it "keeps the credentials for the same origin with an explicit default port" do
        expect(headers_sent_to("#{TEST_HOST}:443/new"))
          .to include("Authorization" => "Bearer #{TEST_ACCESS_TOKEN}")
      end

      it "drops the headers of the caller for another host" do
        stub_request(:get, "https://example.com/new")
        handler.handle(response: redirect(302, "https://example.com/new"), request:, authenticator:,
          headers: {"X-Trace-Id" => "abc123"})

        expect(a_request(:get, "https://example.com/new").with { |req| !req.headers.key?("X-Trace-Id") }).to have_been_made
      end

      it "follows a redirect that does not keep the body to another host" do
        stub_request(:get, "https://example.com/new")
        handler.handle(response: redirect(302, "https://example.com/new"), request: json_request, body: json_body)

        expect(a_request(:get, "https://example.com/new").with { |req| req.body.nil? || req.body.empty? }).to have_been_made
      end

      it "does not restore the credentials on a redirect back" do
        stub_request(:get, "https://example.com/away").to_return(status: 302, headers: {"Location" => "#{TEST_HOST}/back"})
        stub_request(:get, "#{TEST_HOST}/back")
        handler.handle(response: redirect(302, "https://example.com/away"), request:, authenticator:)

        expect(a_request(:get, "#{TEST_HOST}/back").with { |req| !req.headers.key?("Authorization") }).to have_been_made
      end
    end

    context "when a redirect cannot be followed" do
      it "returns a redirect without a Location header" do
        response = Net::HTTPNotModified.new("1.1", "304", "Not Modified")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "returns a redirect whose location is not a valid URL" do
        response = redirect(302, "http://exa mple.com/")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "returns a redirect whose location is not an HTTP URL" do
        response = redirect(302, "ftp://fleet-api.prd.na.vn.cloud.tesla.com/new")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "makes no request" do
        handler.handle(response: redirect(302, "ftp://fleet-api.prd.na.vn.cloud.tesla.com/new"), request:)

        expect(a_request(:any, /.*/)).not_to have_been_made
      end

      it "counts against the maximum redirects first" do
        handler.max_redirects = 0

        expect { handler.handle(response: redirect(302, "ftp://fleet-api.prd.na.vn.cloud.tesla.com/new"), request:) }
          .to raise_error(Tesla::TooManyRedirects)
      end
    end

    it "raises TooManyRedirects after the maximum number of redirects" do
      handler.max_redirects = 2
      stub_request(:get, "#{TEST_HOST}/loop").to_return(status: 302, headers: {"Location" => "/loop"})

      expect { handler.handle(response: redirect(302, "/loop"), request:) }
        .to raise_error(Tesla::TooManyRedirects, "Too many redirects")
    end

    it "follows exactly the maximum number of redirects" do
      handler.max_redirects = 2
      stub_request(:get, "#{TEST_HOST}/loop").to_return(status: 302, headers: {"Location" => "/loop"})
      handler.handle(response: redirect(302, "/loop"), request:)
    rescue Tesla::TooManyRedirects
      expect(a_request(:get, "#{TEST_HOST}/loop")).to have_been_made.times(2)
    end

    it "raises TooManyRedirects when the redirect count already exceeds the maximum" do
      handler.max_redirects = 2

      expect { handler.handle(response: redirect(302, "/new"), request:, redirect_count: 3) }
        .to raise_error(Tesla::TooManyRedirects)
    end

    it "does not follow redirects when the maximum is zero" do
      handler.max_redirects = 0

      expect { handler.handle(response: redirect(302, "/new"), request:) }.to raise_error(Tesla::TooManyRedirects)
    end

    {301 => Net::HTTPMovedPermanently, 302 => Net::HTTPFound, 303 => Net::HTTPSeeOther}.each do |code, klass|
      it "converts a POST to a GET on a #{code}" do
        stub_request(:get, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request: json_request)

        expect(a_request(:get, "#{TEST_HOST}/new")).to have_been_made
      end
    end

    it "drops the body on a 302" do
      stub_request(:get, "#{TEST_HOST}/new")
      handler.handle(response: redirect(302, "/new"), request: json_request, body: json_body)

      expect(a_request(:get, "#{TEST_HOST}/new").with { |req| req.body.nil? || req.body.empty? }).to have_been_made
    end

    {307 => Net::HTTPTemporaryRedirect, 308 => Net::HTTPPermanentRedirect}.each do |code, klass|
      it "preserves the method on a #{code}" do
        request = Net::HTTP::Put.new(URI("#{TEST_HOST}/old"))
        stub_request(:put, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:put, "#{TEST_HOST}/new")).to have_been_made
      end

      it "preserves the headers of the caller on a #{code}" do
        stub_request(:post, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request: json_request, body: json_body,
          headers: {"X-Trace-Id" => "abc123"})

        expect(a_request(:post, "#{TEST_HOST}/new")
          .with(headers: {"X-Trace-Id" => "abc123"})).to have_been_made
      end

      it "preserves the body on a #{code}" do
        stub_request(:post, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request: json_request, body: json_body)

        expect(a_request(:post, "#{TEST_HOST}/new").with(body: '{"key":"value"}')).to have_been_made
      end

      it "preserves a raw body and the content type the caller gave it on a #{code}" do
        headers = {"Content-Type" => "text/plain"}
        request = request_builder.build(http_method: :put, uri: URI("#{TEST_HOST}/old"), body: "raw", headers:)
        stub_request(:put, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request:, body: "raw", headers:)

        expect(a_request(:put, "#{TEST_HOST}/new").with(body: "raw", headers:)).to have_been_made
      end

      it "preserves the body across a second #{code}" do
        stub_request(:post, "#{TEST_HOST}/second").to_return(status: code, headers: {"Location" => "/third"})
        stub_request(:post, "#{TEST_HOST}/third")
        handler.handle(response: redirect(code, "/second", klass:), request: json_request, body: json_body)

        expect(a_request(:post, "#{TEST_HOST}/third").with(body: '{"key":"value"}')).to have_been_made
      end

      it "preserves authentication on a #{code}" do
        authenticator = Tesla::BearerTokenAuthenticator.new(access_token: TEST_ACCESS_TOKEN)
        request = Net::HTTP::Post.new(URI("#{TEST_HOST}/old"))
        stub_request(:post, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request:, authenticator:)

        expect(a_request(:post, "#{TEST_HOST}/new").with(headers: {"Authorization" => "Bearer #{TEST_ACCESS_TOKEN}"})).to have_been_made
      end

      it "preserves the content type on a #{code}" do
        stub_request(:post, "#{TEST_HOST}/new")
        handler.handle(response: redirect(code, "/new", klass:), request: json_request, body: json_body)

        expect(a_request(:post, "#{TEST_HOST}/new")
          .with(headers: {"Content-Type" => "application/json"})).to have_been_made
      end

      context "when a #{code} leaves the origin" do
        it "returns a redirect that would send the body again" do
          response = redirect(code, "https://example.com/new", klass:)

          expect(handler.handle(response:, request: json_request, body: json_body)).to equal(response)
        end

        it "does not send the body to the host the redirect names" do
          stub_request(:post, "https://example.com/new")
          handler.handle(response: redirect(code, "https://example.com/new", klass:), request: json_request,
            body: json_body)

          expect(a_request(:post, "https://example.com/new")).not_to have_been_made
        end

        it "follows a redirect for a request that has no body" do
          stub_request(:get, "https://example.com/new")
          handler.handle(response: redirect(code, "https://example.com/new", klass:), request:)

          expect(a_request(:get, "https://example.com/new")).to have_been_made
        end
      end
    end
  end
end
