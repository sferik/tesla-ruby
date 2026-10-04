# frozen_string_literal: true

RSpec.describe Tesla::User do
  subject(:user) { described_class.new(attributes) }

  let(:attributes) do
    {"email" => "nikola@example.com",
     "full_name" => "Nikola Tesla",
     "profile_image_url" => "https://example.com/nikola.jpg"}
  end

  it "is a Resource" do
    expect(user).to be_a(Tesla::Resource)
  end

  it "is identified by its email" do
    expect(user.send(:identity)).to eq(["nikola@example.com"])
  end

  it "inspects as its email" do
    expect(user.inspect).to eq("#<Tesla::User email=\"nikola@example.com\">")
  end

  it "exposes the email" do
    expect(user.email).to eq("nikola@example.com")
  end

  it "exposes the full name" do
    expect(user.full_name).to eq("Nikola Tesla")
  end

  it "exposes the profile image url" do
    expect(user.profile_image_url).to eq("https://example.com/nikola.jpg")
  end
end
