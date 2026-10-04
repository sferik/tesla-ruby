# Security Policy

## Supported versions

Security fixes are released for the most recent minor release of the current major series.

## Reporting a vulnerability

Please do not report security vulnerabilities through public GitHub issues, pull requests, or discussions.

Report them privately through [GitHub security advisories](https://github.com/sferik/tesla-ruby/security/advisories/new),
or by email to [sferik@gmail.com](mailto:sferik@gmail.com). Include the version of the gem, the Ruby version, and the
steps to reproduce the problem.

## What this library handles

This library sends credentials to the Tesla Fleet API and to Tesla's authorization server: OAuth 2.0 access tokens,
refresh tokens, and the client secret of an application. Those credentials can unlock and start a car, so reports
about the way they are stored, sent, logged, or resolved are particularly welcome. It already takes these
precautions, so a way around one of them is a vulnerability rather than a feature request:

* `inspect` output for clients and authenticators never includes credentials.
* The values interpolated into request paths are escaped, so a vehicle tag or a command name holding a slash cannot
  walk out of the endpoint it was meant for and take the access token of the request with it.
* A request path that is a URL of another host, or that climbs out of the path prefix of the host, is refused rather
  than sent the access token.
* Credentials are redacted from `debug_output`, which Net::HTTP would otherwise write in the clear: the
  `Authorization` header of a request, the `Proxy-Authorization` header of a request sent through a proxy and of
  the CONNECT that opens a TLS connection through one, the tokens and the client secret of a request to the token
  endpoint and of its response, and the PIN or password of a command.
* A redirect to another scheme, host, or port is followed without the access token or the caller's headers, and one
  that would send the body of the request again is not followed at all, so that a command cannot be replayed to a
  host the client was not pointed at.
* A command is never sent a second time on its own: a request that asks a vehicle to do something is retried only
  when a rate limiter turned it away before it reached the vehicle, and is sent on a connection of its own rather
  than on one kept open, which the server may have closed.
* TLS certificates are verified, and no option turns that off: a host whose certificate OpenSSL does not already
  trust, such as the vehicle command proxy, is reached by naming that certificate with `ca_file`.
