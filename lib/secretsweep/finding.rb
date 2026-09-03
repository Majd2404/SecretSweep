# frozen_string_literal: true

require "digest"

module SecretSweep
  # A single detected secret. Immutable value object — findings are
  # produced once and never mutated, only filtered (by IgnoreList) or
  # rendered (by Reporter).
  Finding = Struct.new(:source, :line_number, :type, :snippet, :commit) do
    def fingerprint
      # Stable identifier for this finding, used by the ignore list to
      # allowlist a specific known false positive without silencing the
      # entire rule everywhere else. Based on content, not line number,
      # so it survives the file being edited above the secret.
      Digest::SHA256.hexdigest("#{source}:#{type}:#{redacted_snippet}")[0, 12]
    end

    def redacted_snippet
      return snippet if snippet.length <= 8

      "#{snippet[0, 4]}...#{snippet[-4, 4]}"
    end

    def to_h
      {
        source: source,
        line: line_number,
        type: type,
        snippet: redacted_snippet,
        commit: commit,
        fingerprint: fingerprint
      }.compact
    end
  end
end
