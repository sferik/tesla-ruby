# frozen_string_literal: true

RSpec.describe Tesla::DriveState do
  subject(:drive_state) { described_class.new(attributes) }

  let(:attributes) do
    {"latitude" => 33.111111,
     "longitude" => -88.111111,
     "heading" => 5,
     "speed" => 65,
     "power" => -9,
     "shift_state" => "D",
     "timestamp" => 1607623897515}
  end

  it "is a Resource" do
    expect(drive_state).to be_a(Tesla::Resource)
  end

  it "inspects as its latitude and longitude and shift state" do
    expect(drive_state.inspect).to eq("#<Tesla::DriveState latitude=33.111111 longitude=-88.111111 shift_state=\"D\">")
  end

  it "exposes the latitude" do
    expect(drive_state.latitude).to eq(33.111111)
  end

  it "exposes the longitude" do
    expect(drive_state.longitude).to eq(-88.111111)
  end

  it "exposes the heading" do
    expect(drive_state.heading).to eq(5)
  end

  it "exposes the speed" do
    expect(drive_state.speed).to eq(65)
  end

  it "exposes the power" do
    expect(drive_state.power).to eq(-9)
  end

  it "exposes the shift state" do
    expect(drive_state.shift_state).to eq("D")
  end

  it "exposes the timestamp as a Time" do
    expect(drive_state.timestamp).to eq(Time.utc(2020, 12, 10, 18, 11, 37, 515_000))
  end
end
