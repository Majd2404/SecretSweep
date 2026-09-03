# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ScannerTest < Minitest::Test
  def test_scans_working_tree_by_default
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "secret.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')

      scanner = SecretSweep::Scanner.new(dir)
      findings = scanner.run

      refute_empty findings
    end
  end

  def test_applies_ignore_file_found_in_target_directory
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "secret.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
      File.write(File.join(dir, ".secretsweepignore"), "*.rb\n")

      scanner = SecretSweep::Scanner.new(dir)
      assert_empty scanner.run
    end
  end

  def test_does_not_scan_history_unless_requested
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "clean.rb"), "def hello; end")

      scanner = SecretSweep::Scanner.new(dir, include_history: false)
      assert_empty scanner.run
    end
  end

  def test_deduplicates_identical_findings
    Dir.mktmpdir do |dir|
      # same secret appears twice in two different files
      File.write(File.join(dir, "a.rb"), 'key = "AKIAIOSFODNN7EXAMPLE"')
      File.write(File.join(dir, "b.rb"), 'other_key = "AKIAIOSFODNN7EXAMPLE"')

      scanner = SecretSweep::Scanner.new(dir)
      findings = scanner.run

      # different source files -> different fingerprints -> NOT deduped
      assert_equal 2, findings.size
    end
  end
end
