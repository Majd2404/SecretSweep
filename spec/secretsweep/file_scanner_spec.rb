# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe SecretSweep::FileScanner do
  fixture_dir = File.expand_path("../fixtures", __dir__)

  describe "#scan" do
    it "finds known secret patterns in the fixture" do
      findings = described_class.new(fixture_dir).scan
      types = findings.map(&:type)

      expect(types).to include("aws_access_key_id", "github_token", "stripe_test_key")
    end

    it "does not flag placeholder or ordinary code" do
      findings = described_class.new(fixture_dir).scan
      snippets = findings.map(&:snippet)

      expect(snippets).not_to include(a_string_matching(/your_api_key_goes_here/))
    end

    it "respects ignore list path globs" do
      ignore_list = SecretSweep::IgnoreList.new(["*.rb"], [])
      findings = described_class.new(fixture_dir, ignore_list: ignore_list).scan

      expect(findings).to be_empty
    end

    it "skips binary files" do
      Dir.mktmpdir do |dir|
        binary_path = File.join(dir, "image.png")
        File.binwrite(binary_path, "\x89PNG\x00\x00AKIAIOSFODNN7EXAMPLE")

        findings = described_class.new(dir).scan
        expect(findings).to be_empty
      end
    end

    it "skips common noise directories" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, "node_modules"))
        File.write(File.join(dir, "node_modules", "leak.js"), 'const key = "AKIAIOSFODNN7EXAMPLE";')

        expect(described_class.new(dir).scan).to be_empty
      end
    end

    it "reports the correct line number" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "config.rb"), "line one\nline two\nkey = \"AKIAIOSFODNN7EXAMPLE\"\n")

        findings = described_class.new(dir).scan
        aws_finding = findings.find { |f| f.type == "aws_access_key_id" }

        expect(aws_finding).not_to be_nil
        expect(aws_finding.line_number).to eq(3)
      end
    end
  end
end
