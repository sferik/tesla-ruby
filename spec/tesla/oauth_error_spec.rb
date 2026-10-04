# frozen_string_literal: true

RSpec.describe Tesla::OAuthError do
  subject(:error) { described_class.new(code: "invalid_grant", description: "The refresh token is expired.", status: 401) }

  it "names the error code and the description in the message" do
    expect(error.message).to eq("invalid_grant: The refresh token is expired.")
  end

  it "names the error code alone when the response carried no description" do
    expect(described_class.new(code: "invalid_grant", status: 401).message).to eq("invalid_grant")
  end

  it "names the description alone when the response carried no error code" do
    expect(described_class.new(description: "The response has no access token", status: 200).message)
      .to eq("The response has no access token")
  end

  it "names the status when the response carried neither" do
    expect(described_class.new(status: 503).message).to eq("The token endpoint answered with status 503")
  end

  it "exposes the error code" do
    expect(error.code).to eq("invalid_grant")
  end

  it "exposes the description" do
    expect(error.description).to eq("The refresh token is expired.")
  end

  it "exposes the status" do
    expect(error.status).to eq(401)
  end

  it "defaults the error code, the description, and the status to nil" do
    expect(described_class.new).to have_attributes(code: nil, description: nil, status: nil)
  end
end
