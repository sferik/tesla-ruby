# frozen_string_literal: true

RSpec.describe Tesla::Region do
  subject(:region) { described_class.new(attributes) }

  let(:attributes) do
    {"region" => "eu",
     "fleet_api_base_url" => "https://fleet-api.prd.eu.vn.cloud.tesla.com"}
  end

  it "is a Resource" do
    expect(region).to be_a(Tesla::Resource)
  end

  it "inspects as its region" do
    expect(region.inspect).to eq("#<Tesla::Region region=\"eu\">")
  end

  it "exposes the region" do
    expect(region.region).to eq("eu")
  end

  it "exposes the fleet api base url" do
    expect(region.fleet_api_base_url).to eq("https://fleet-api.prd.eu.vn.cloud.tesla.com")
  end
end
