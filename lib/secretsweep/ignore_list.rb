# frozen_string_literal: true

module SecretSweep
  # Parses a .secretsweepignore file with two kinds of entries:
  #   - a bare glob pattern (e.g. `spec/fixtures/**`) skips scanning those
  #     paths entirely
  #   - a 12-char fingerprint (as printed in a Finding's report) allowlists
  #     that ONE specific known false positive, not the whole rule
  #
  # This distinction matters: silencing an entire secret TYPE because one
  # file has a false positive would blind the scanner everywhere else.
  class IgnoreList
    def self.load(path)
      return new([], []) unless path && File.exist?(path)

      globs = []
      fingerprints = []

      File.readlines(path).each do |raw_line|
        line = raw_line.strip
        next if line.empty? || line.start_with?("#")

        if line.match?(/\A[0-9a-f]{12}\z/)
          fingerprints << line
        else
          globs << line
        end
      end

      new(globs, fingerprints)
    end

    def initialize(path_globs, fingerprints)
      @path_globs = path_globs
      @fingerprints = fingerprints
    end

    def path_ignored?(path)
      @path_globs.any? { |glob| File.fnmatch(glob, path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
    end

    def finding_ignored?(finding)
      @fingerprints.include?(finding.fingerprint)
    end

    def reject_ignored(findings)
      findings.reject { |f| finding_ignored?(f) }
    end
  end
end
