# frozen_string_literal: true

require "test_helper"

class PatternRegistryTest < Minitest::Test
  def test_detects_aws_access_key_id
    line = "aws_access_key = 'AKIAIOSFODNN7EXAMPLE'"
    matches = SecretSweep::PatternRegistry.scan_line(line)

    refute_empty matches
    assert(matches.any? { |m| m[:type] == "aws_access_key_id" })
  end

  def test_detects_github_token
    line = 'token = "ghp_1234567890abcdefghijklmnopqrstuvwxyz12"'
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert(matches.any? { |m| m[:type] == "github_token" })
  end

  def test_does_not_match_github_token_shorter_than_minimum_length
    line = 'token = "ghp_tooshort"'
    matches = SecretSweep::PatternRegistry.scan_line(line)

    refute(matches.any? { |m| m[:type] == "github_token" })
  end

  def test_detects_generic_private_key_header
    line = "-----BEGIN RSA PRIVATE KEY-----"
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert(matches.any? { |m| m[:type] == "generic_private_key" })
  end

  def test_detects_stripe_test_key
    line = "STRIPE_SECRET_KEY=sk_test_4eC39HqLyjWDarjtT1zdp7dc"
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert(matches.any? { |m| m[:type] == "stripe_test_key" })
  end

  def test_ignores_lines_with_placeholder_hints
    line = 'api_key = "your_api_key_goes_here_xxxxxxxxxxxxxxxx"'
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert_empty matches
  end

  def test_ignores_ordinary_code_with_no_secrets
    line = "def calculate_total(items); items.sum(&:price); end"
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert_empty matches
  end

  def test_does_not_false_positive_on_short_generic_assignment
    line = 'password = "abc"'
    matches = SecretSweep::PatternRegistry.scan_line(line)

    assert_empty matches
  end
end
