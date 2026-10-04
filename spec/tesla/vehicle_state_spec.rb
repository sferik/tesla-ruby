# frozen_string_literal: true

RSpec.describe Tesla::VehicleState do
  subject(:vehicle_state) { described_class.new(attributes) }

  let(:attributes) do
    {"car_version" => "2020.48.10 f8900cddd03a",
     "odometer" => 57869.762487,
     "vehicle_name" => "Nikola 2.0",
     "sun_roof_state" => "closed",
     "locked" => true,
     "sentry_mode" => true,
     "valet_mode" => true,
     "is_user_present" => true,
     "remote_start" => true,
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(vehicle_state).to be_a(Tesla::Resource)
  end

  it "inspects as its car version and odometer" do
    expect(vehicle_state.inspect).to eq("#<Tesla::VehicleState car_version=\"2020.48.10 f8900cddd03a\" odometer=57869.762487>")
  end

  it "exposes the car version" do
    expect(vehicle_state.car_version).to eq("2020.48.10 f8900cddd03a")
  end

  it "exposes the odometer" do
    expect(vehicle_state.odometer).to eq(57869.762487)
  end

  it "exposes the vehicle name" do
    expect(vehicle_state.vehicle_name).to eq("Nikola 2.0")
  end

  it "exposes the sun roof state" do
    expect(vehicle_state.sun_roof_state).to eq("closed")
  end

  it "exposes whether locked" do
    expect(vehicle_state.locked?).to be(true)
  end

  it "exposes whether sentry mode" do
    expect(vehicle_state.sentry_mode?).to be(true)
  end

  it "exposes whether valet mode" do
    expect(vehicle_state.valet_mode?).to be(true)
  end

  it "exposes whether user present" do
    expect(vehicle_state.user_present?).to be(true)
  end

  it "exposes whether remote start" do
    expect(vehicle_state.remote_start?).to be(true)
  end

  it "exposes the timestamp as a Time" do
    expect(vehicle_state.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end

  describe "#frunk_open?" do
    it "is true when the front trunk is open" do
      expect(described_class.new("ft" => 16).frunk_open?).to be(true)
    end

    it "is false when the front trunk is closed" do
      expect(described_class.new("ft" => 0, "rt" => 1).frunk_open?).to be(false)
    end

    it "is false when the response does not say" do
      expect(vehicle_state.frunk_open?).to be(false)
    end
  end

  describe "#trunk_open?" do
    it "is true when the rear trunk is open" do
      expect(described_class.new("rt" => 1).trunk_open?).to be(true)
    end

    it "is false when the rear trunk is closed" do
      expect(described_class.new("rt" => 0, "ft" => 1).trunk_open?).to be(false)
    end

    it "is false when the response does not say" do
      expect(vehicle_state.trunk_open?).to be(false)
    end
  end
end
