# frozen_string_literal: true

require "spec_helper"

RSpec.describe SecretSweep::Finding do
  describe "#redacted_snippet" do
    it "redacts long snippets" do
      finding = described_class.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      expect(finding.redacted_snippet).to eq("AKIA...MPLE")
    end

    it "does not redact short snippets" do
      finding = described_class.new("app.rb", 10, "generic", "short", nil)
      expect(finding.redacted_snippet).to eq("short")
    end
  end

  describe "#fingerprint" do
    it "is stable for identical findings regardless of line number" do
      a = described_class.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      b = described_class.new("app.rb", 99, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)

      expect(a.fingerprint).to eq(b.fingerprint)
    end

    it "differs for different secrets" do
      a = described_class.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      b = described_class.new("app.rb", 10, "aws_access_key_id", "AKIADIFFERENTKEY1234", nil)

      expect(a.fingerprint).not_to eq(b.fingerprint)
    end
  end

  describe "#to_h" do
    it "includes the redacted snippet, not the raw secret" do
      finding = described_class.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      hash = finding.to_h

      expect(hash[:snippet]).not_to eq("AKIAIOSFODNN7EXAMPLE")
      expect(hash[:snippet]).to eq(finding.redacted_snippet)
    end
  end
end
