# frozen_string_literal: true

RSpec.describe Tesla::CommandFailed do
  subject(:error) { described_class.new(command: "charge_start", reason: "disconnected") }

  it "exposes the command" do
    expect(error.command).to eq("charge_start")
  end

  it "exposes the reason" do
    expect(error.reason).to eq("disconnected")
  end

  it "names the command and the reason in the message" do
    expect(error.message).to eq("The vehicle did not carry out charge_start: disconnected")
  end

  it "names the command alone when the vehicle gave no reason" do
    expect(described_class.new(command: "charge_start", reason: "").message).to eq("The vehicle did not carry out charge_start")
  end

  it "reads a missing reason as an empty one" do
    expect(described_class.new(command: "charge_start", reason: nil))
      .to have_attributes(reason: "", message: "The vehicle did not carry out charge_start")
  end
end
