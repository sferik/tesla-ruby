# frozen_string_literal: true

RSpec.describe Tesla::CertificateOptions do
  subject(:options) { Class.new { include Tesla::CertificateOptions }.new }

  describe "#ca_file" do
    it "is nil until a file is assigned" do
      expect(options.ca_file).to be_nil
    end
  end

  describe "#ca_file=" do
    it "assigns the path of a file" do
      options.ca_file = certificate_path("ca.pem")

      expect(options.ca_file).to eq(certificate_path("ca.pem"))
    end

    it "assigns nil, to verify with the certificates OpenSSL trusts" do
      options.ca_file = certificate_path("ca.pem")
      options.ca_file = nil

      expect(options.ca_file).to be_nil
    end

    it "raises for a path that names nothing" do
      expect { options.ca_file = certificate_path("missing.pem") }
        .to raise_error(ArgumentError, "Invalid CA file: #{certificate_path("missing.pem")}")
    end

    it "raises for a path that names a directory" do
      expect { options.ca_file = certificate_path }.to raise_error(ArgumentError, "Invalid CA file: #{certificate_path}")
    end

    it "leaves the file as it was after a path it refuses" do
      options.ca_file = certificate_path("ca.pem")
      options.ca_file = certificate_path("missing.pem")
    rescue ArgumentError
      expect(options.ca_file).to eq(certificate_path("ca.pem"))
    end
  end
end
