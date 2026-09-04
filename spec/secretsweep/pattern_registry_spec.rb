# frozen_string_literal: true

require "spec_helper"

RSpec.describe SecretSweep::PatternRegistry do
  describe ".scan_line" do
    it "detects an AWS access key id" do
      line = "aws_access_key = 'AKIAIOSFODNN7EXAMPLE'"
      matches = described_class.scan_line(line)

      expect(matches).not_to be_empty
      expect(matches).to include(a_hash_including(type: "aws_access_key_id"))
    end

    it "detects a GitHub token" do
      line = 'token = "ghp_1234567890abcdefghijklmnopqrstuvwxyz12"'
      matches = described_class.scan_line(line)

      expect(matches).to include(a_hash_including(type: "github_token"))
    end

    it "does not match a GitHub token shorter than the minimum length" do
      line = 'token = "ghp_tooshort"'
      matches = described_class.scan_line(line)

      expect(matches).not_to include(a_hash_including(type: "github_token"))
    end

    it "detects a generic private key header" do
      line = "-----BEGIN RSA PRIVATE KEY-----"
      matches = described_class.scan_line(line)

      expect(matches).to include(a_hash_including(type: "generic_private_key"))
    end

    it "detects a Stripe test key" do
      line = "STRIPE_SECRET_KEY=sk_test_51NqA9K2mP8vQ3xR7tY6wZ0bC4dE"
      matches = described_class.scan_line(line)

      expect(matches).to include(a_hash_including(type: "stripe_test_key"))
    end

    it "ignores lines with placeholder hints" do
      line = 'api_key = "your_api_key_goes_here_xxxxxxxxxxxxxxxx"'
      expect(described_class.scan_line(line)).to be_empty
    end

    it "ignores ordinary code with no secrets" do
      line = "def calculate_total(items); items.sum(&:price); end"
      expect(described_class.scan_line(line)).to be_empty
    end

    it "does not false-positive on a short generic assignment" do
      line = 'password = "abc"'
      expect(described_class.scan_line(line)).to be_empty
    end
  end
end
