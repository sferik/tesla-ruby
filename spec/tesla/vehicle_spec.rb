# frozen_string_literal: true

RSpec.describe Tesla::Vehicle do
  subject(:vehicle) { described_class.new(attributes) }

  let(:attributes) do
    {"id" => 12345678901234567,
     "vehicle_id" => 1234567890,
     "vin" => "5YJSA11111111111",
     "display_name" => "Nikola 2.0",
     "state" => "online",
     "access_type" => "OWNER",
     "api_version" => 13,
     "in_service" => true}
  end

  it "is a Resource" do
    expect(vehicle).to be_a(Tesla::Resource)
  end

  it "is identified by its vin" do
    expect(vehicle.send(:identity)).to eq(["5YJSA11111111111"])
  end

  it "inspects as its vin and display name and state" do
    expect(vehicle.inspect).to eq("#<Tesla::Vehicle vin=\"5YJSA11111111111\" display_name=\"Nikola 2.0\" state=\"online\">")
  end

  it "exposes the id" do
    expect(vehicle.id).to eq(12345678901234567)
  end

  it "exposes the vehicle id" do
    expect(vehicle.vehicle_id).to eq(1234567890)
  end

  it "exposes the vin" do
    expect(vehicle.vin).to eq("5YJSA11111111111")
  end

  it "exposes the display name" do
    expect(vehicle.display_name).to eq("Nikola 2.0")
  end

  it "exposes the state" do
    expect(vehicle.state).to eq("online")
  end

  it "exposes the access type" do
    expect(vehicle.access_type).to eq("OWNER")
  end

  it "exposes the api version" do
    expect(vehicle.api_version).to eq(13)
  end

  it "exposes whether in service" do
    expect(vehicle.in_service?).to be(true)
  end

  describe "#online?" do
    it "is true for a vehicle that is online" do
      expect(vehicle.online?).to be(true)
    end

    it "is false for a vehicle that is asleep" do
      expect(described_class.new("state" => "asleep").online?).to be(false)
    end

    it "is false for a vehicle without a state" do
      expect(described_class.new({}).online?).to be(false)
    end
  end
end
