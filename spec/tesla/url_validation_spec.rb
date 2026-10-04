# frozen_string_literal: true

RSpec.describe Tesla::URLValidation do
  subject(:validator) { Class.new { include Tesla::URLValidation }.new }

  describe "#validate_host" do
    it "returns a host that is an HTTPS URL" do
      expect(validator.send(:validate_host, TEST_HOST)).to eq(TEST_HOST)
    end

    it "returns a host that is an HTTP URL" do
      expect(validator.send(:validate_host, "http://localhost:8080")).to eq("http://localhost:8080")
    end

    it "raises for a host that is not an HTTP URL" do
      expect { validator.send(:validate_host, "ftp://tesla.example.com") }
        .to raise_error(ArgumentError, "Invalid host: ftp://tesla.example.com")
    end

    it "leaves the user and password out of the message for a host that is not an HTTP URL" do
      expect { validator.send(:validate_host, "ftp://user:secret@tesla.example.com") }
        .to raise_error(ArgumentError, "Invalid host: ftp://tesla.example.com")
    end

    it "raises for a host that is not a String" do
      expect { validator.send(:validate_host, nil) }.to raise_error(ArgumentError, "Invalid host: ")
    end

    it "raises for a host that is neither a String nor nil" do
      expect { validator.send(:validate_host, 4443) }.to raise_error(ArgumentError, "Invalid host: 4443")
    end

    it "raises for a host that carries a user and password, without showing them" do
      expect { validator.send(:validate_host, "https://user:secret@tesla.example.com") }
        .to raise_error(ArgumentError, "Invalid host: https://tesla.example.com carries a user and password, which are not sent")
    end
  end

  describe "#parse_proxy_uri" do
    it "returns the URI of an HTTP proxy" do
      expect(validator.send(:parse_proxy_uri, "http://proxy.example.com:8080")).to eq(URI("http://proxy.example.com:8080"))
    end

    it "returns the URI of an HTTPS proxy" do
      expect(validator.send(:parse_proxy_uri, "https://proxy.example.com")).to be_an_instance_of(URI::HTTPS)
    end

    it "raises for a proxy that is not an HTTP URL, without showing its user and password" do
      expect { validator.send(:parse_proxy_uri, "ftp://user:secret@proxy.example.com/") }
        .to raise_error(ArgumentError, "Invalid proxy URL: ftp://proxy.example.com/")
    end

    it "raises for a proxy URL that cannot be parsed, without showing its user and password" do
      expect { validator.send(:parse_proxy_uri, "http://user:secret@proxy example.com/") }
        .to raise_error(ArgumentError, "Invalid proxy URL: http://proxy example.com/")
    end
  end

  describe "#http_url?" do
    it "is true for an HTTPS URL" do
      expect(validator.send(:http_url?, TEST_HOST)).to be(true)
    end

    it "is true for an HTTP URL" do
      expect(validator.send(:http_url?, "http://localhost:8080")).to be(true)
    end

    it "is false for a URL of another scheme" do
      expect(validator.send(:http_url?, "ftp://tesla.example.com")).to be(false)
    end

    it "is false for an HTTP URL without a host" do
      expect(validator.send(:http_url?, "http:///api")).to be(false)
    end

    it "is false for an HTTP URL that names nothing after its scheme" do
      expect(validator.send(:http_url?, "http:")).to be(false)
    end

    it "is false for a String that is not a URL with a scheme" do
      expect(validator.send(:http_url?, "tesla.example.com")).to be(false)
    end

    it "is false for a String that cannot be parsed" do
      expect(validator.send(:http_url?, "https://tesla example.com")).to be(false)
    end

    it "is false for a value that is not a String" do
      expect(validator.send(:http_url?, nil)).to be(false)
    end
  end

  describe "#build_uri" do
    it "joins the host and the path" do
      expect(validator.send(:build_uri, TEST_HOST, "/api/1/vehicles")).to eq(URI("#{TEST_HOST}/api/1/vehicles"))
    end

    it "takes a path without a leading slash" do
      expect(validator.send(:build_uri, TEST_HOST, "api/1/vehicles")).to eq(URI("#{TEST_HOST}/api/1/vehicles"))
    end

    it "keeps the path prefix of the host" do
      expect(validator.send(:build_uri, "https://tesla.example.com/fleet", "/api/1/vehicles"))
        .to eq(URI("https://tesla.example.com/fleet/api/1/vehicles"))
    end

    it "keeps the path prefix of a host that ends with a slash" do
      expect(validator.send(:build_uri, "https://tesla.example.com/fleet/", "api/1/vehicles"))
        .to eq(URI("https://tesla.example.com/fleet/api/1/vehicles"))
    end

    it "reads a path that starts with two slashes as a path on the host, rather than as another host" do
      expect(validator.send(:build_uri, TEST_HOST, "//example.com/api")).to eq(URI("#{TEST_HOST}/example.com/api"))
    end

    it "takes a path that is a URL on the host" do
      expect(validator.send(:build_uri, TEST_HOST, "#{TEST_HOST}/api/1/vehicles")).to eq(URI("#{TEST_HOST}/api/1/vehicles"))
    end

    it "refuses a path that is a URL of another host" do
      expect { validator.send(:build_uri, TEST_HOST, "https://example.com/api") }
        .to raise_error(ArgumentError, "Path is not on #{TEST_HOST}: https://example.com/api")
    end

    it "refuses a path that climbs out of the prefix of the host" do
      expect { validator.send(:build_uri, "https://tesla.example.com/fleet", "../api") }
        .to raise_error(ArgumentError, "Path is not on https://tesla.example.com/fleet: ../api")
    end
  end

  describe "#same_origin?" do
    it "is true for URLs of the same scheme, host, and port" do
      expect(validator.send(:same_origin?, "#{TEST_HOST}/api/1/vehicles", URI(TEST_HOST))).to be(true)
    end

    it "is true whatever the case of the scheme and the host" do
      expect(validator.send(:same_origin?, "HTTPS://Tesla.Example.COM/api", "https://tesla.example.com")).to be(true)
    end

    it "is true for the default port, written out or not" do
      expect(validator.send(:same_origin?, "https://tesla.example.com:443", "https://tesla.example.com")).to be(true)
    end

    it "is false for another scheme" do
      expect(validator.send(:same_origin?, "http://tesla.example.com", "https://tesla.example.com")).to be(false)
    end

    it "is false for another host" do
      expect(validator.send(:same_origin?, "https://example.com", "https://tesla.example.com")).to be(false)
    end

    it "is false for another port" do
      expect(validator.send(:same_origin?, "https://tesla.example.com:4443", "https://tesla.example.com")).to be(false)
    end
  end

  describe "#on_host?" do
    it "is true for a URL of a host without a prefix" do
      expect(validator.send(:on_host?, URI("#{TEST_HOST}/api/1/vehicles"), TEST_HOST)).to be(true)
    end

    it "is true for a URL under the prefix of the host" do
      expect(validator.send(:on_host?, URI("https://tesla.example.com/fleet/api"), "https://tesla.example.com/fleet")).to be(true)
    end

    it "is true for a URL under a prefix that ends with a slash" do
      expect(validator.send(:on_host?, URI("https://tesla.example.com/fleet/api"), "https://tesla.example.com/fleet/")).to be(true)
    end

    it "is false for a URL outside the prefix of the host" do
      expect(validator.send(:on_host?, URI("https://tesla.example.com/api"), "https://tesla.example.com/fleet")).to be(false)
    end

    it "is false for a URL whose path only starts as the prefix does" do
      expect(validator.send(:on_host?, URI("https://tesla.example.com/fleets"), "https://tesla.example.com/fleet")).to be(false)
    end

    it "is false for a URL of another origin" do
      expect(validator.send(:on_host?, URI("https://example.com/api"), TEST_HOST)).to be(false)
    end

    it "is false for a URL without a path, rather than reading the path it does not have" do
      expect(validator.send(:on_host?, URI("mailto:nikola@example.com"), TEST_HOST)).to be(false)
    end
  end

  describe "#origin" do
    it "is the scheme, the host, and the port of a URL, with the scheme and the host in lowercase" do
      expect(validator.send(:origin, "HTTPS://Tesla.Example.COM:4443/api")).to eq(["https", "tesla.example.com", 4443])
    end

    it "reads a URI as it reads a String" do
      expect(validator.send(:origin, URI(TEST_HOST))).to eq(["https", "fleet-api.prd.na.vn.cloud.tesla.com", 443])
    end
  end

  describe "#redact" do
    it "removes the user and password of a URL" do
      expect(validator.send(:redact, "http://user:secret@proxy.example.com:8080/")).to eq("http://proxy.example.com:8080/")
    end

    it "removes an empty user and password" do
      expect(validator.send(:redact, "http://@proxy.example.com")).to eq("http://proxy.example.com")
    end

    it "leaves a URL without a user and password as it is" do
      expect(validator.send(:redact, "http://proxy.example.com/a@b")).to eq("http://proxy.example.com/a@b")
    end

    it "is nil for nil" do
      expect(validator.send(:redact, nil)).to be_nil
    end
  end
end
