# frozen_string_literal: true

require "uri"

module Tesla
  # Checks and compares the URLs a host, a proxy, and a redirect are given as, mixed into the configuration, the
  # client, the connection, and the redirect handler
  #
  # A URL is checked where it is assigned rather than when a request is made with it, so that the error names the
  # assignment that was wrong instead of the call that happened to send the next request. The value that is rejected
  # is left as it was.
  #
  # @api private
  module URLValidation
    private

    # Check that a host is a URL requests can be sent to
    #
    # A host that carries a user and password, such as "https://user:pass@tesla.example.com", is refused: Net::HTTP
    # sends neither, and the host is shown by {Client#inspect} and in error messages, which would show the
    # password. The message the host is refused with leaves them out.
    #
    # @api private
    # @param host [String] the host, including scheme
    # @return [String] the host
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, or carries a user and password
    def validate_host(host)
      raise ArgumentError, "Invalid host: #{redact(host.to_s)}" unless http_url?(host)
      if URI(host).userinfo
        raise ArgumentError, "Invalid host: #{redact(host)} carries a user and password, which are not sent"
      end

      host
    end

    # Parse and validate a proxy URL
    #
    # @api private
    # @param proxy_url [String] the proxy URL
    # @return [URI::HTTP] the proxy URI
    # @raise [ArgumentError] if the proxy URL is not a valid HTTP or HTTPS URL; the message leaves out its user and
    #   password
    def parse_proxy_uri(proxy_url)
      proxy_uri = URI(proxy_url)
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}" unless proxy_uri.is_a?(URI::HTTP)

      proxy_uri
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}"
    end

    # Whether a host is an HTTP or HTTPS URL with a host
    # @api private
    # @param host [Object] the host
    # @return [Boolean] whether the host is a URL requests can be sent to
    def http_url?(host)
      uri = URI(host)
      uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
    rescue ArgumentError, URI::InvalidURIError
      false
    end

    # Join a host and a request path, keeping any path prefix on the host
    #
    # A path that is a URL of its own is refused rather than followed to the host it names, since the access token
    # of a request is the one issued for the host it was meant for, and a path that moved the request to another
    # host would take the token with it.
    #
    # A path that climbs out of the prefix the host carries, such as "../.." for a host of
    # "https://tesla.example.com/fleet", is refused for the same reason: the client was pointed at that prefix, and
    # a path that leaves it asks the rest of the host with the access token of the client. A host without a prefix
    # names the whole of its origin, so there is nothing to climb out of.
    #
    # @api private
    # @param host [String] the host, optionally carrying a path prefix
    # @param path [String] the request path
    # @return [URI] the request URI
    # @raise [ArgumentError] if the path is a URL of an origin other than the host, or climbs out of its prefix
    def build_uri(host, path)
      uri = URI.join("#{host.chomp("/")}/", path.delete_prefix("/"))
      raise ArgumentError, "Path is not on #{host}: #{path}" unless on_host?(uri, host)

      uri
    end

    # Whether two URLs share a scheme, host, and port
    #
    # @api private
    # @param url [String, URI::Generic] one URL
    # @param other [String, URI::Generic] the other URL
    # @return [Boolean] whether the URLs share an origin
    def same_origin?(url, other)
      origin(url).eql?(origin(other))
    end

    # Whether a URL is the host's own, at or under the path the host names
    #
    # The path is compared as well as the origin, so that a URL climbing out of the prefix a host carries, such as
    # "../.." for "https://tesla.example.com/fleet", is told from one the host was pointed at, as a URL of
    # another scheme, host, or port is. A host that carries no prefix names the whole of its origin, so every URL
    # of that origin is on it.
    #
    # The paths are read once the origins are known to match, so a URL that has none, such as a "mailto:" URL, is
    # answered by the comparison of the origins rather than by reading the path it does not have.
    #
    # @api private
    # @param uri [URI::Generic] the URL, as the URI it was read as
    # @param host [String, URI::Generic] the host, optionally carrying a path prefix
    # @return [Boolean] whether the URL is the host's own, at or under the path it names
    def on_host?(uri, host)
      same_origin?(uri, host) && uri.path.start_with?("#{URI(host).path.chomp("/")}/") # steep:ignore NoMethod
    end

    # The origin of a URL, with the scheme and host in lowercase
    # @api private
    # @param url [String, URI::Generic] the URL
    # @return [Array] the scheme, host, and port
    def origin(url)
      uri = URI(url).normalize
      [uri.scheme, uri.host, uri.port]
    end

    # Remove the user and password from a URL
    # @api private
    # @param url [String, nil] the URL
    # @return [String, nil] the URL without its userinfo, or nil for nil
    def redact(url)
      url&.sub(%r{(?<=//)[^/@]*@}, "")
    end
  end
end
