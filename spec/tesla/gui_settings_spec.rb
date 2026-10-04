# frozen_string_literal: true

RSpec.describe Tesla::GUISettings do
  subject(:gui_settings) { described_class.new(attributes) }

  let(:attributes) do
    {"gui_distance_units" => "mi/hr",
     "gui_temperature_units" => "F",
     "gui_charge_rate_units" => "kW",
     "gui_range_display" => "Rated",
     "gui_24_hour_time" => true,
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(gui_settings).to be_a(Tesla::Resource)
  end

  it "inspects as its distance units and temperature units" do
    expect(gui_settings.inspect).to eq("#<Tesla::GUISettings distance_units=\"mi/hr\" temperature_units=\"F\">")
  end

  it "exposes the distance units" do
    expect(gui_settings.distance_units).to eq("mi/hr")
  end

  it "exposes the temperature units" do
    expect(gui_settings.temperature_units).to eq("F")
  end

  it "exposes the charge rate units" do
    expect(gui_settings.charge_rate_units).to eq("kW")
  end

  it "exposes the range display" do
    expect(gui_settings.range_display).to eq("Rated")
  end

  it "exposes whether twenty four hour time" do
    expect(gui_settings.twenty_four_hour_time?).to be(true)
  end

  it "exposes the timestamp as a Time" do
    expect(gui_settings.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end
end
