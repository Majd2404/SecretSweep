# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe SecretSweep::IgnoreList do
  describe ".load" do
    it "returns an empty list when no file is given" do
      list = described_class.load(nil)
      expect(list.path_ignored?("anything.rb")).to be(false)
    end

    it "parses path globs and fingerprints separately" do
      Dir.mktmpdir do |dir|
        ignore_path = File.join(dir, ".secretsweepignore")
        File.write(ignore_path, <<~IGNORE)
          # comment line should be skipped
          spec/fixtures/**
          a1b2c3d4e5f6
        IGNORE

        list = described_class.load(ignore_path)

        expect(list.path_ignored?("spec/fixtures/sample.txt")).to be(true)
        expect(list.path_ignored?("app/models/user.rb")).to be(false)
      end
    end
  end

  describe "#finding_ignored?" do
    it "matches by fingerprint" do
      finding = SecretSweep::Finding.new("app.rb", 1, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      list = described_class.new([], [finding.fingerprint])

      expect(list.finding_ignored?(finding)).to be(true)
    end
  end

  describe "#reject_ignored" do
    it "filters out allowlisted findings only" do
      finding = SecretSweep::Finding.new("app.rb", 1, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
      other = SecretSweep::Finding.new("app.rb", 2, "github_token", "ghp_abcdefghijklmnopqrstuvwxyz123456", nil)

      list = described_class.new([], [finding.fingerprint])
      result = list.reject_ignored([finding, other])

      expect(result).to eq([other])
    end
  end
end
