# frozen_string_literal: true

module SecretSweep
  # Public entry point for running a scan. Combines FileScanner and
  # (optionally) GitHistoryScanner, applies the ignore list once at the
  # end so both scanners share identical allowlisting behavior instead of
  # each reimplementing it.
  class Scanner
    def initialize(path, ignore_file: nil, include_history: false)
      @path = File.expand_path(path)
      @ignore_list = IgnoreList.load(ignore_file || default_ignore_path)
      @include_history = include_history
    end

    def run
      findings = FileScanner.new(@path, ignore_list: @ignore_list).scan

      findings.concat(GitHistoryScanner.new(@path, ignore_list: @ignore_list).scan) if @include_history

      dedupe(@ignore_list.reject_ignored(findings))
    end

    private

    def default_ignore_path
      candidate = File.join(@path, ".secretsweepignore")
      File.exist?(candidate) ? candidate : nil
    end

    # The same secret often appears in both the working tree AND history
    # (e.g. it's still there right now). Collapse to one entry per unique
    # fingerprint so the report doesn't double-count it, while keeping the
    # entry with the most specific location.
    def dedupe(findings)
      findings.group_by(&:fingerprint).map { |_fp, group| group.first }
    end
  end
end
