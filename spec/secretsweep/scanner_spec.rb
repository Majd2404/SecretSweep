# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe SecretSweep::Scanner do
  describe "#run" do
    it "scans the working tree by default" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "secret.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')

        findings = described_class.new(dir).run
        expect(findings).not_to be_empty
      end
    end

    it "applies an ignore file found in the target directory" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "secret.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
        File.write(File.join(dir, ".secretsweepignore"), "*.rb\n")

        expect(described_class.new(dir).run).to be_empty
      end
    end

    it "does not scan history unless requested" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "clean.rb"), "def hello; end")

        findings = described_class.new(dir, include_history: false).run
        expect(findings).to be_empty
      end
    end

    it "does not deduplicate the same secret found in two different files" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "a.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
        File.write(File.join(dir, "b.rb"), 'other_key = "AKIAIOSFODNN7EXAMPLE"')

        findings = described_class.new(dir).run
        expect(findings.size).to eq(2)
      end
    end
  end
end
