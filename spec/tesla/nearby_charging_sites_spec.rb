# frozen_string_literal: true

RSpec.describe Tesla::NearbyChargingSites do
  subject(:nearby_charging_sites) do
    described_class.new(JSON.parse(fixture("nearby_charging_sites.json").read).fetch("response"))
  end

  it "is a Resource" do
    expect(nearby_charging_sites).to be_a(Tesla::Resource)
  end

  it "exposes the Superchargers" do
    expect(nearby_charging_sites.superchargers)
      .to all(be_an_instance_of(Tesla::ChargingSite)).and have_attributes(size: 2, first: have_attributes(available_stalls: 4))
  end

  it "exposes the destination chargers" do
    expect(nearby_charging_sites.destination_charging.map(&:name)).to eq(["Hilton Garden Inn Atlanta NW/Kennesaw Town Center"])
  end

  it "exposes the timestamp as a Time" do
    expect(nearby_charging_sites.timestamp).to eq(Time.utc(2020, 11, 10, 2, 48, 9, 279_000))
  end

  it "answers with no sites for a response without any" do
    expect(described_class.new({})).to have_attributes(superchargers: [], destination_charging: [])
  end
end
