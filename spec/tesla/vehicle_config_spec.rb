# frozen_string_literal: true

RSpec.describe Tesla::VehicleConfig do
  subject(:vehicle_config) { described_class.new(attributes) }

  let(:attributes) do
    {"car_type" => "models2",
     "trim_badging" => "p90d",
     "exterior_color" => "White",
     "wheel_type" => "AeroTurbine19",
     "charge_port_type" => "US",
     "sun_roof_installed" => 2,
     "can_actuate_trunks" => true,
     "plg" => true,
     "rhd" => true,
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(vehicle_config).to be_a(Tesla::Resource)
  end

  it "inspects as its car type and trim badging" do
    expect(vehicle_config.inspect).to eq("#<Tesla::VehicleConfig car_type=\"models2\" trim_badging=\"p90d\">")
  end

  it "exposes the car type" do
    expect(vehicle_config.car_type).to eq("models2")
  end

  it "exposes the trim badging" do
    expect(vehicle_config.trim_badging).to eq("p90d")
  end

  it "exposes the exterior color" do
    expect(vehicle_config.exterior_color).to eq("White")
  end

  it "exposes the wheel type" do
    expect(vehicle_config.wheel_type).to eq("AeroTurbine19")
  end

  it "exposes the charge port type" do
    expect(vehicle_config.charge_port_type).to eq("US")
  end

  it "exposes the sun roof installed" do
    expect(vehicle_config.sun_roof_installed).to eq(2)
  end

  it "exposes whether can actuate trunks" do
    expect(vehicle_config.can_actuate_trunks?).to be(true)
  end

  it "exposes whether power liftgate" do
    expect(vehicle_config.power_liftgate?).to be(true)
  end

  it "exposes whether right hand drive" do
    expect(vehicle_config.right_hand_drive?).to be(true)
  end

  it "exposes the timestamp as a Time" do
    expect(vehicle_config.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end
end
