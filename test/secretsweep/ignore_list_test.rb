# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class IgnoreListTest < Minitest::Test
  def test_load_returns_empty_list_when_no_file_given
    list = SecretSweep::IgnoreList.load(nil)
    refute list.path_ignored?("anything.rb")
  end

  def test_parses_path_globs_and_fingerprints_separately
    Dir.mktmpdir do |dir|
      ignore_path = File.join(dir, ".secretsweepignore")
      File.write(ignore_path, <<~IGNORE)
        # comment line should be skipped
        spec/fixtures/**
        a1b2c3d4e5f6
      IGNORE

      list = SecretSweep::IgnoreList.load(ignore_path)

      assert list.path_ignored?("spec/fixtures/sample.txt")
      refute list.path_ignored?("app/models/user.rb")
    end
  end

  def test_finding_ignored_matches_by_fingerprint
    finding = SecretSweep::Finding.new("app.rb", 1, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
    list = SecretSweep::IgnoreList.new([], [finding.fingerprint])

    assert list.finding_ignored?(finding)
  end

  def test_reject_ignored_filters_out_allowlisted_findings
    finding = SecretSweep::Finding.new("app.rb", 1, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
    other = SecretSweep::Finding.new("app.rb", 2, "github_token", "ghp_abcdefghijklmnopqrstuvwxyz123456", nil)

    list = SecretSweep::IgnoreList.new([], [finding.fingerprint])
    result = list.reject_ignored([finding, other])

    assert_equal [other], result
  end
end
