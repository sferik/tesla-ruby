# frozen_string_literal: true

RSpec.describe Tesla::ChargeState do
  subject(:charge_state) { described_class.new(attributes) }

  let(:attributes) do
    {"battery_level" => 59,
     "usable_battery_level" => 58,
     "battery_range" => 149.92,
     "charge_limit_soc" => 90,
     "charging_state" => "Charging",
     "charge_amps" => 32,
     "charge_rate" => 28.0,
     "charger_power" => 9,
     "minutes_to_full_charge" => 165,
     "charge_port_latch" => "Engaged",
     "charge_port_door_open" => true,
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(charge_state).to be_a(Tesla::Resource)
  end

  it "inspects as its battery level and charging state" do
    expect(charge_state.inspect).to eq("#<Tesla::ChargeState battery_level=59 charging_state=\"Charging\">")
  end

  it "exposes the battery level" do
    expect(charge_state.battery_level).to eq(59)
  end

  it "exposes the usable battery level" do
    expect(charge_state.usable_battery_level).to eq(58)
  end

  it "exposes the battery range" do
    expect(charge_state.battery_range).to eq(149.92)
  end

  it "exposes the charge limit" do
    expect(charge_state.charge_limit).to eq(90)
  end

  it "exposes the charging state" do
    expect(charge_state.charging_state).to eq("Charging")
  end

  it "exposes the charge amps" do
    expect(charge_state.charge_amps).to eq(32)
  end

  it "exposes the charge rate" do
    expect(charge_state.charge_rate).to eq(28.0)
  end

  it "exposes the charger power" do
    expect(charge_state.charger_power).to eq(9)
  end

  it "exposes the minutes to full charge" do
    expect(charge_state.minutes_to_full_charge).to eq(165)
  end

  it "exposes the charge port latch" do
    expect(charge_state.charge_port_latch).to eq("Engaged")
  end

  it "exposes whether charge port door open" do
    expect(charge_state.charge_port_door_open?).to be(true)
  end

  it "exposes the timestamp as a Time" do
    expect(charge_state.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end
end
