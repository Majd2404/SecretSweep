# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "open3"

class GitHistoryScannerTest < Minitest::Test
  def test_raises_on_non_git_directory
    Dir.mktmpdir do |dir|
      scanner = SecretSweep::GitHistoryScanner.new(dir)
      assert_raises(SecretSweep::GitHistoryScanner::NotAGitRepoError) { scanner.scan }
    end
  end

  def test_finds_secret_committed_and_later_removed
    Dir.mktmpdir do |dir|
      init_repo(dir)

      # Commit 1: add a secret
      File.write(File.join(dir, "config.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
      git(dir, "add", "config.rb")
      git(dir, "commit", "-m", "add config")

      # Commit 2: remove it — but it's still in history
      File.write(File.join(dir, "config.rb"), "key = ENV['AWS_KEY']")
      git(dir, "add", "config.rb")
      git(dir, "commit", "-m", "remove hardcoded secret")

      scanner = SecretSweep::GitHistoryScanner.new(dir)
      findings = scanner.scan

      assert(findings.any? { |f| f.type == "aws_access_key_id" },
             "expected the scanner to find the secret still present in git history")
    end
  end

  private

  def init_repo(dir)
    git(dir, "init", "-q")
    git(dir, "config", "user.email", "test@example.com")
    git(dir, "config", "user.name", "Test")
  end

  def git(dir, *args)
    _out, status = Open3.capture2("git", "-C", dir, *args)
    raise "git command failed: #{args.join(' ')}" unless status.success?
  end
end
