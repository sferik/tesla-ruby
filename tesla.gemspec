# frozen_string_literal: true

require_relative "lib/tesla/version"

Gem::Specification.new do |spec|
  spec.name = "tesla"
  spec.version = Tesla::VERSION
  spec.authors = ["Erik Berlin"]
  spec.email = ["sferik@gmail.com"]

  spec.summary = "Ruby wrapper for the Tesla Fleet API"
  spec.description = "A client for the Tesla Fleet API that reads the state of a vehicle and commands it, with " \
    "immutable response objects, OAuth 2.0 token refresh, and retries"
  spec.homepage = "https://github.com/sferik/tesla-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "https://github.com/sferik/tesla-ruby/issues",
    "changelog_uri" => "https://github.com/sferik/tesla-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/tesla/",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/sferik/tesla-ruby"
  }

  spec.files = Dir.glob([
    ".yardopts",
    "lib/**/*.rb",
    "sig/*.rbs",
    "sig/manifest.yaml",
    "*.md",
    "LICENSE.md"
  ], base: __dir__)
  spec.require_paths = ["lib"]

  spec.add_dependency "simple_oauth", "1.0.1"
end
