# frozen_string_literal: true

module Tesla
  # The certificates TLS is verified with, mixed into the configuration and the connection
  #
  # A host whose certificate Ruby's OpenSSL does not already trust, such as the vehicle command proxy with a
  # certificate of its own, is reached by naming that certificate here rather than by turning verification off:
  # there is no option for that, so a request of this library is always verified.
  #
  # The path is checked where it is assigned, as a host and a proxy URL are (see {URLValidation}), so that a path
  # that names nothing is reported as the assignment that was wrong instead of as the TLS failure of the next
  # request. The value that is rejected is left as it was.
  #
  # @api private
  module CertificateOptions
    # The path of a file of certificates TLS is verified with
    #
    # The certificates in the file are trusted alongside the ones OpenSSL already trusts.
    #
    # @api private
    # @return [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    # @example Get the CA file
    #   connection.ca_file
    attr_reader :ca_file

    # Set the path of a file of certificates TLS is verified with
    #
    # @api private
    # @param ca_file [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    # @return [void]
    # @raise [ArgumentError] if the path does not name a file, in which case the path is left as it was
    # @example Set the CA file
    #   connection.ca_file = "config/tls-cert.pem"
    def ca_file=(ca_file)
      @ca_file = ca_file && validate_ca_file(ca_file)
    end

    private

    # Check that a path names a file of certificates
    # @api private
    # @param ca_file [String] the path of the file
    # @return [String] the path
    # @raise [ArgumentError] if the path does not name a file
    def validate_ca_file(ca_file)
      raise ArgumentError, "Invalid CA file: #{ca_file}" unless File.file?(ca_file)

      ca_file
    end
  end
end
