# frozen_string_literal: true

RSpec.describe Tesla::VehicleData do
  subject(:vehicle_data) { described_class.new(JSON.parse(fixture("vehicle_data.json").read).fetch("response")) }

  it "is a Vehicle" do
    expect(vehicle_data).to be_a(Tesla::Vehicle)
  end

  it "declares the readers of a vehicle and of its states" do
    expect(described_class.attribute_names).to eq(Tesla::Vehicle.attribute_names +
      %i[charge_state climate_state drive_state gui_settings vehicle_config vehicle_state])
  end

  it "inspects as a vehicle does" do
    expect(vehicle_data.inspect).to eq('#<Tesla::VehicleData vin="5YJSA11111111111" display_name="Nikola 2.0" state="online">')
  end

  it "exposes the charge state" do
    expect(vehicle_data.charge_state).to be_an_instance_of(Tesla::ChargeState).and have_attributes(battery_level: 59)
  end

  it "exposes the climate state" do
    expect(vehicle_data.climate_state).to be_an_instance_of(Tesla::ClimateState).and have_attributes(inside_temp: 22.1)
  end

  it "exposes the drive state" do
    expect(vehicle_data.drive_state).to be_an_instance_of(Tesla::DriveState).and have_attributes(heading: 5)
  end

  it "exposes the GUI settings" do
    expect(vehicle_data.gui_settings).to be_an_instance_of(Tesla::GUISettings).and have_attributes(temperature_units: "F")
  end

  it "exposes the vehicle config" do
    expect(vehicle_data.vehicle_config).to be_an_instance_of(Tesla::VehicleConfig).and have_attributes(car_type: "models2")
  end

  it "exposes the vehicle state" do
    expect(vehicle_data.vehicle_state).to be_an_instance_of(Tesla::VehicleState).and have_attributes(odometer: 57_869.762487)
  end

  it "answers nil for a state the Fleet API was not asked for" do
    expect(described_class.new("vin" => TEST_VIN).charge_state).to be_nil
  end
end
