# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

unless $PROGRAM_NAME.include?("mutant") || RUBY_ENGINE.eql?("jruby")
  require "simplecov"

  SimpleCov.start "strict"
end

# The environment the library falls back to until a host or a credential is assigned. A developer who has exported
# one would otherwise have it resolved by the examples that exercise those fallbacks, which sends their own
# credential to the request stubs and leaves it in whatever those runs record. It is cleared before the library is
# required, since the module reads the host as it is loaded.
%w[TESLA_HOST TESLA_ACCESS_TOKEN TESLA_REFRESH_TOKEN TESLA_CLIENT_ID TESLA_CLIENT_SECRET TESLA_REDIRECT_URI]
  .each { |name| ENV.delete(name) }

require "tesla"
require "openssl"
require "rspec"
require "tmpdir"
require "webmock/rspec"

# A certificate authority for the examples that name one, generated rather than committed so that the repository
# carries no PEM private key for a secret scanner to flag
def build_test_certificate(key)
  name = OpenSSL::X509::Name.parse("/CN=Tesla Test CA")
  fields = {version: 2, serial: 1, subject: name, issuer: name, public_key: key,
            not_before: Time.now - 60, not_after: Time.now + 3600}
  OpenSSL::X509::Certificate.new.tap do |certificate|
    fields.each { |field, value| certificate.public_send(:"#{field}=", value) }
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))
  end
end

TEST_CERTIFICATE_DIRECTORY = Dir.mktmpdir("tesla-certificates")
# Only the process that made the directory removes it: mutant forks a process per mutation, and a fork removing it
# on the way out would take it from the mutations that run after
TEST_CERTIFICATE_PID = Process.pid
at_exit { FileUtils.remove_entry(TEST_CERTIFICATE_DIRECTORY, true) if Process.pid.eql?(TEST_CERTIFICATE_PID) }
File.write(File.join(TEST_CERTIFICATE_DIRECTORY, "ca.pem"),
  build_test_certificate(OpenSSL::PKey::EC.generate("prime256v1")).to_pem)

WebMock.disable_net_connect!

TEST_HOST = "https://fleet-api.prd.na.vn.cloud.tesla.com"
TEST_TOKEN_ENDPOINT = "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
TEST_ACCESS_TOKEN = "TEST_ACCESS_TOKEN"
TEST_REFRESH_TOKEN = "TEST_REFRESH_TOKEN"
TEST_CLIENT_ID = "TEST_CLIENT_ID"
TEST_CLIENT_SECRET = "TEST_CLIENT_SECRET"
TEST_REDIRECT_URI = "https://example.com/auth/callback"
TEST_VIN = "5YJSA11111111111"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    Tesla.reset
  end
end

def fixture_path
  File.expand_path("fixtures", __dir__)
end

def fixture(file)
  File.new(File.join(fixture_path, file), "rb")
end

def certificate_path(file = nil)
  File.join(TEST_CERTIFICATE_DIRECTORY, *file)
end

def stub_get(url)
  stub_request(:get, tesla_url(url))
end

def stub_post(url)
  stub_request(:post, tesla_url(url))
end

def a_get(url)
  a_request(:get, tesla_url(url))
end

def a_post(url)
  a_request(:post, tesla_url(url))
end

def tesla_url(url)
  return url if url.start_with?("http")

  TEST_HOST + url
end

# Stub a command of the test vehicle, which the vehicle answers by saying it carried it out
def stub_command(name, result: true, reason: "")
  stub_post("/api/1/vehicles/#{TEST_VIN}/command/#{name}").to_return(body: JSON.generate(response: {result:, reason:}))
end

def a_command(name)
  a_post("/api/1/vehicles/#{TEST_VIN}/command/#{name}")
end

# Stub the token endpoint, which answers with tokens of the names given
def stub_token(access_token: "NEW_ACCESS_TOKEN", refresh_token: "NEW_REFRESH_TOKEN")
  body = JSON.generate({access_token:, refresh_token:, expires_in: 28_800, token_type: "Bearer"}.compact)
  stub_request(:post, TEST_TOKEN_ENDPOINT).to_return(body:)
end

def a_token_request
  a_request(:post, TEST_TOKEN_ENDPOINT)
end

def with_env(env)
  original = env.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
  env.each { |key, value| ENV[key] = value }
  yield
ensure
  original.each { |key, value| ENV[key] = value }
end

def build_response(response_class, code, message, body)
  response = response_class.new("1.1", code, message)
  response.instance_variable_set(:@read, true)
  response.body = body
  response
end
