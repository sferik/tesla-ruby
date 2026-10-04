# frozen_string_literal: true

RSpec.describe Tesla::ChargingSite do
  subject(:charging_site) { described_class.new(attributes) }

  let(:attributes) do
    {"name" => "Atlanta, GA - Peachtree Road",
     "type" => "supercharger",
     "distance_miles" => 10.868304,
     "available_stalls" => 4,
     "total_stalls" => 5,
     "location" => {"lat" => 33.848756, "long" => -84.36434},
     "site_closed" => true}
  end

  it "is a Resource" do
    expect(charging_site).to be_a(Tesla::Resource)
  end

  it "inspects as its name and type" do
    expect(charging_site.inspect).to eq("#<Tesla::ChargingSite name=\"Atlanta, GA - Peachtree Road\" type=\"supercharger\">")
  end

  it "exposes the name" do
    expect(charging_site.name).to eq("Atlanta, GA - Peachtree Road")
  end

  it "exposes the type" do
    expect(charging_site.type).to eq("supercharger")
  end

  it "exposes the distance miles" do
    expect(charging_site.distance_miles).to eq(10.868304)
  end

  it "exposes the available stalls" do
    expect(charging_site.available_stalls).to eq(4)
  end

  it "exposes the total stalls" do
    expect(charging_site.total_stalls).to eq(5)
  end

  it "exposes the location" do
    expect(charging_site.location).to eq({"lat" => 33.848756, "long" => -84.36434})
  end

  it "exposes whether site closed" do
    expect(charging_site.site_closed?).to be(true)
  end
end
