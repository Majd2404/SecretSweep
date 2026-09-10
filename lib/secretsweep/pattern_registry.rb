# frozen_string_literal: true

module SecretSweep
  # Known secret formats, keyed by a short type name. Each pattern is
  # intentionally specific (not a generic "any long string" catch-all —
  # that's what Entropy.high_entropy? is for) to keep false positives low
  # for the formats we DO recognize.
  module PatternRegistry
    PATTERNS = {
      "aws_access_key_id" => /\bAKIA[0-9A-Z]{16}\b/,
      "aws_secret_access_key" => %r{\baws(.{0,20})?(secret|access)[_-]?key\b.{0,5}['"]([A-Za-z0-9/+=]{40})['"]}i,
      "github_token" => /\bgh[pousr]_[A-Za-z0-9]{36,}\b/,
      "slack_token" => /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/,
      "stripe_live_key" => /\bsk_live_[A-Za-z0-9]{24,}\b/,
      "stripe_test_key" => /\bsk_test_[A-Za-z0-9]{24,}\b/,
      "generic_private_key" => /-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----/,
      "google_api_key" => /\bAIza[0-9A-Za-z\-_]{35}\b/,
      "generic_api_key_assignment" =>
        %r{\b(api[_-]?key|secret|token|password|passwd|pwd)\b\s*[:=]\s*['"][A-Za-z0-9/+=_-]{16,}['"]}i,
      "jwt" => /\bey[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/
    }.freeze

    # Lines matching any of these are skipped entirely before pattern
    # matching runs — cuts down on noise from example/placeholder values
    # that would otherwise trip the generic_api_key_assignment pattern.
    #
    # "your_api_key" and "xxxx+" are deliberately NOT wrapped in a trailing
    # \b: that phrase commonly appears glued to surrounding text via
    # underscores (e.g. "your_api_key_goes_here"), and \b never fires
    # between two word characters — underscore counts as one — so a
    # trailing boundary there would silently fail to match exactly the
    # placeholder text it exists to catch.
    PLACEHOLDER_HINTS = /\b(example|placeholder|changeme|dummy|fake|sample)\b|your[_-]?api[_-]?key|xxxx+/i

    # Returns an array of { type:, snippet: } hashes for every match found
    # in the line. The snippet is the full matched text — callers (e.g.
    # Finding) are responsible for redacting it before display/storage.
    def self.scan_line(line)
      # Defensively normalize encoding: a file read outside a UTF-8 locale
      # (e.g. LANG unset) can hand us a string whose declared encoding
      # doesn't match its bytes, which makes regex matching raise instead
      # of just returning "no match". `scrub` replaces invalid byte
      # sequences so scanning degrades gracefully instead of aborting the
      # whole file's scan.
      line = line.to_s.scrub
      return [] if line.match?(PLACEHOLDER_HINTS)

      PATTERNS.each_with_object([]) do |(type, regex), matches|
        line.scan(regex) { matches << { type: type, snippet: Regexp.last_match(0) } }
      end
    end
  end
end
