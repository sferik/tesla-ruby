# frozen_string_literal: true

RSpec.describe Tesla::Settings do
  subject(:validator) { settings_class.new }

  let(:settings_class) { Class.new { include Tesla::Settings } }

  describe ".included" do
    it "extends the class with the macros that declare the settings" do
      expect(settings_class.singleton_class).to include(Tesla::Settings::Declaration)
    end
  end

  describe "#seconds_setting" do
    subject(:object) { settings_class.new }

    before { settings_class.send(:seconds_setting, :read_timeout) }

    it "reads the seconds it was assigned" do
      object.read_timeout = 0.5

      expect(object.read_timeout).to eq(0.5)
    end

    it "reads nothing until it is assigned" do
      expect(object.read_timeout).to be_nil
    end

    it "refuses a value that is not a number of seconds" do
      expect { object.read_timeout = -1 }.to raise_error(ArgumentError, "Invalid read_timeout: -1")
    end
  end

  describe "#count_setting" do
    subject(:object) { settings_class.new }

    before { settings_class.send(:count_setting, :max_retries) }

    it "reads the count it was assigned" do
      object.max_retries = 3

      expect(object.max_retries).to eq(3)
    end

    it "reads nothing until it is assigned" do
      expect(object.max_retries).to be_nil
    end

    it "refuses a value that is not a count" do
      expect { object.max_retries = 1.5 }.to raise_error(ArgumentError, "Invalid max_retries: 1.5")
    end
  end

  describe "#environment_setting" do
    subject(:object) { settings_class.new }

    before { settings_class.send(:environment_setting, :client_id, "TESLA_CLIENT_ID") }

    it "reads nothing while neither the setting nor the environment variable is assigned" do
      expect(object.client_id).to be_nil
    end

    it "reads the environment variable until the setting is assigned" do
      with_env("TESLA_CLIENT_ID" => "ENV_CLIENT_ID") { expect(object.client_id).to eq("ENV_CLIENT_ID") }
    end

    it "reads the value it was assigned rather than the environment variable" do
      object.client_id = TEST_CLIENT_ID

      with_env("TESLA_CLIENT_ID" => "ENV_CLIENT_ID") { expect(object.client_id).to eq(TEST_CLIENT_ID) }
    end

    it "reads nil once it was assigned nil, rather than the environment variable" do
      object.client_id = nil

      with_env("TESLA_CLIENT_ID" => "ENV_CLIENT_ID") { expect(object.client_id).to be_nil }
    end

    it "keeps the setting of one object from the others" do
      object.client_id = TEST_CLIENT_ID

      expect(settings_class.new.client_id).to be_nil
    end
  end

  describe "#validate_number" do
    [60, 0, 0.5, Rational(1, 2)].each do |seconds|
      it "answers with #{seconds.inspect}" do
        expect(validator.send(:validate_number, :read_timeout, seconds)).to eql(seconds)
      end
    end

    [-1, -0.5, "60", nil, true, Float::NAN].each do |seconds|
      it "raises for #{seconds.inspect}" do
        expect { validator.send(:validate_number, :read_timeout, seconds) }
          .to raise_error(ArgumentError, "Invalid read_timeout: #{seconds.inspect}")
      end
    end

    it "names the setting that was assigned" do
      expect { validator.send(:validate_number, :max_retry_delay, -1) }
        .to raise_error(ArgumentError, "Invalid max_retry_delay: -1")
    end
  end

  describe "#validate_count" do
    [2, 0].each do |count|
      it "answers with #{count.inspect}" do
        expect(validator.send(:validate_count, :max_retries, count)).to eql(count)
      end
    end

    [-1, 1.5, Rational(1, 2), "2", nil, true].each do |count|
      it "raises for #{count.inspect}" do
        expect { validator.send(:validate_count, :max_retries, count) }
          .to raise_error(ArgumentError, "Invalid max_retries: #{count.inspect}")
      end
    end

    it "names the setting that was assigned" do
      expect { validator.send(:validate_count, :max_redirects, -1) }
        .to raise_error(ArgumentError, "Invalid max_redirects: -1")
    end
  end
end
