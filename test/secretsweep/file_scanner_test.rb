# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class FileScannerTest < Minitest::Test
  FIXTURE_DIR = File.expand_path("../fixtures", __dir__)

  def test_finds_known_secret_patterns_in_fixture
    scanner = SecretSweep::FileScanner.new(FIXTURE_DIR)
    findings = scanner.scan

    types = findings.map(&:type)
    assert_includes types, "aws_access_key_id"
    assert_includes types, "github_token"
    assert_includes types, "stripe_test_key"
  end

  def test_does_not_flag_placeholder_or_ordinary_code
    scanner = SecretSweep::FileScanner.new(FIXTURE_DIR)
    findings = scanner.scan

    snippets = findings.map(&:snippet)
    refute(snippets.any? { |s| s.include?("your_api_key_goes_here") })
  end

  def test_respects_ignore_list_path_globs
    ignore_list = SecretSweep::IgnoreList.new(["*.rb"], [])
    scanner = SecretSweep::FileScanner.new(FIXTURE_DIR, ignore_list: ignore_list)

    assert_empty scanner.scan
  end

  def test_skips_binary_files
    Dir.mktmpdir do |dir|
      binary_path = File.join(dir, "image.png")
      File.binwrite(binary_path, "\x89PNG\x00\x00AKIAIOSFODNN7EXAMPLE")

      scanner = SecretSweep::FileScanner.new(dir)
      findings = scanner.scan

      assert_empty findings
    end
  end

  def test_skips_common_noise_directories
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "node_modules"))
      File.write(File.join(dir, "node_modules", "leak.js"), 'const key = "AKIAIOSFODNN7EXAMPLE";')

      scanner = SecretSweep::FileScanner.new(dir)
      assert_empty scanner.scan
    end
  end

  def test_finding_has_correct_line_number
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "config.rb"), "line one\nline two\nkey = \"AKIAIOSFODNN7EXAMPLE\"\n")

      scanner = SecretSweep::FileScanner.new(dir)
      findings = scanner.scan

      aws_finding = findings.find { |f| f.type == "aws_access_key_id" }
      refute_nil aws_finding
      assert_equal 3, aws_finding.line_number
    end
  end
end
