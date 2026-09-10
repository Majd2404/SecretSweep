# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "open3"

RSpec.describe SecretSweep::GitHistoryScanner do
  describe "#scan" do
    it "raises on a non-git directory" do
      Dir.mktmpdir do |dir|
        scanner = described_class.new(dir)
        expect { scanner.scan }.to raise_error(SecretSweep::GitHistoryScanner::NotAGitRepoError)
      end
    end

    it "finds a secret that was committed and later removed" do
      Dir.mktmpdir do |dir|
        init_repo(dir)

        # Commit 1: add a secret
        File.write(File.join(dir, "config.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
        run_git(dir, "add", "config.rb")
        run_git(dir, "commit", "-m", "add config")

        # Commit 2: remove it — but it's still in history
        File.write(File.join(dir, "config.rb"), "key = ENV['AWS_KEY']")
        run_git(dir, "add", "config.rb")
        run_git(dir, "commit", "-m", "remove hardcoded secret")

        findings = described_class.new(dir).scan

        expect(findings).to include(an_object_having_attributes(type: "aws_access_key_id"))
      end
    end
  end

  def init_repo(dir)
    run_git(dir, "init", "-q")
    run_git(dir, "config", "user.email", "test@example.com")
    run_git(dir, "config", "user.name", "Test")
  end

  def run_git(dir, *args)
    _out, status = Open3.capture2("git", "-C", dir, *args)
    raise "git command failed: #{args.join(" ")}" unless status.success?
  end
end
