# frozen_string_literal: true

RSpec.describe Tesla::VehicleAsleep do
  subject(:error) { described_class.new(vehicle:) }

  let(:vehicle) { Tesla::Vehicle.new("vin" => TEST_VIN, "state" => "asleep") }

  it "exposes the vehicle" do
    expect(error.vehicle).to equal(vehicle)
  end

  it "names the state of the vehicle in the message" do
    expect(error.message).to eq('The vehicle is still "asleep" rather than online')
  end
end
