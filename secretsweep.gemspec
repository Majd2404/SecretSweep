# frozen_string_literal: true

require_relative "lib/secretsweep/version"

Gem::Specification.new do |spec|
  spec.name = "secretsweep"
  spec.version = SecretSweep::VERSION
  spec.authors = ["Majd"]
  spec.summary = "A dependency-free CLI that scans files and git history for leaked secrets."
  spec.description = <<~DESC
    SecretSweep scans a codebase (and optionally its full git history) for
    leaked secrets — API keys, tokens, private keys — using a combination
    of known-format regex patterns and Shannon entropy analysis for
    unknown formats. Pure Ruby standard library, zero runtime dependencies.
  DESC
  spec.homepage = "https://github.com/Majd2404/SecretSweep"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = ["secretsweep"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.20"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.60"
end
