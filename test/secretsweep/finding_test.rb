# frozen_string_literal: true

require "test_helper"

class FindingTest < Minitest::Test
  def test_redacts_long_snippets
    finding = SecretSweep::Finding.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)

    assert_equal "AKIA...MPLE", finding.redacted_snippet
  end

  def test_does_not_redact_short_snippets
    finding = SecretSweep::Finding.new("app.rb", 10, "generic", "short", nil)

    assert_equal "short", finding.redacted_snippet
  end

  def test_fingerprint_is_stable_for_identical_findings
    a = SecretSweep::Finding.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
    b = SecretSweep::Finding.new("app.rb", 99, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)

    # Same source/type/snippet -> same fingerprint even if line number differs
    assert_equal a.fingerprint, b.fingerprint
  end

  def test_fingerprint_differs_for_different_secrets
    a = SecretSweep::Finding.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
    b = SecretSweep::Finding.new("app.rb", 10, "aws_access_key_id", "AKIADIFFERENTKEY1234", nil)

    refute_equal a.fingerprint, b.fingerprint
  end

  def test_to_h_includes_redacted_snippet_not_raw_secret
    finding = SecretSweep::Finding.new("app.rb", 10, "aws_access_key_id", "AKIAIOSFODNN7EXAMPLE", nil)
    hash = finding.to_h

    refute_equal "AKIAIOSFODNN7EXAMPLE", hash[:snippet]
    assert_equal finding.redacted_snippet, hash[:snippet]
  end
end
