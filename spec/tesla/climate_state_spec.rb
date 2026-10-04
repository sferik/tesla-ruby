# frozen_string_literal: true

RSpec.describe Tesla::ClimateState do
  subject(:climate_state) { described_class.new(attributes) }

  let(:attributes) do
    {"inside_temp" => 22.1,
     "outside_temp" => 18.0,
     "driver_temp_setting" => 21.1,
     "passenger_temp_setting" => 21.5,
     "fan_status" => 3,
     "climate_keeper_mode" => "dog",
     "seat_heater_left" => 2,
     "seat_heater_right" => 1,
     "is_climate_on" => true,
     "is_preconditioning" => true,
     "is_front_defroster_on" => true,
     "is_rear_defroster_on" => true,
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(climate_state).to be_a(Tesla::Resource)
  end

  it "inspects as its inside temp and driver temp setting" do
    expect(climate_state.inspect).to eq("#<Tesla::ClimateState inside_temp=22.1 driver_temp_setting=21.1>")
  end

  it "exposes the inside temp" do
    expect(climate_state.inside_temp).to eq(22.1)
  end

  it "exposes the outside temp" do
    expect(climate_state.outside_temp).to eq(18.0)
  end

  it "exposes the driver temp setting" do
    expect(climate_state.driver_temp_setting).to eq(21.1)
  end

  it "exposes the passenger temp setting" do
    expect(climate_state.passenger_temp_setting).to eq(21.5)
  end

  it "exposes the fan status" do
    expect(climate_state.fan_status).to eq(3)
  end

  it "exposes the climate keeper mode" do
    expect(climate_state.climate_keeper_mode).to eq("dog")
  end

  it "exposes the seat heater left" do
    expect(climate_state.seat_heater_left).to eq(2)
  end

  it "exposes the seat heater right" do
    expect(climate_state.seat_heater_right).to eq(1)
  end

  it "exposes whether climate on" do
    expect(climate_state.climate_on?).to be(true)
  end

  it "exposes whether preconditioning" do
    expect(climate_state.preconditioning?).to be(true)
  end

  it "exposes whether front defroster on" do
    expect(climate_state.front_defroster_on?).to be(true)
  end

  it "exposes whether rear defroster on" do
    expect(climate_state.rear_defroster_on?).to be(true)
  end

  it "exposes the timestamp as a Time" do
    expect(climate_state.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end
end
