# frozen_string_literal: true

require "json"

module SecretSweep
  # Renders a list of Findings for human or machine consumption. Kept
  # separate from Scanner so output format never leaks into detection
  # logic — adding a new format (e.g. SARIF for GitHub code scanning)
  # means touching only this file.
  module Reporter
    module_function

    def render(findings, format: :text)
      case format
      when :json then render_json(findings)
      else render_text(findings)
      end
    end

    def render_text(findings)
      return "No secrets found.\n" if findings.empty?

      lines = ["Found #{findings.size} potential secret(s):", ""]
      findings.each do |f|
        location = f.commit ? "#{f.source} @ #{f.commit}" : "#{f.source}:#{f.line_number}"
        lines << "  [#{f.type}] #{location}"
        lines << "    #{f.redacted_snippet}  (fingerprint: #{f.fingerprint})"
      end
      lines << ""
      lines << "To allowlist a confirmed false positive, add its fingerprint to .secretsweepignore"
      "#{lines.join("\n")}\n"
    end

    def render_json(findings)
      JSON.pretty_generate(
        count: findings.size,
        findings: findings.map(&:to_h)
      )
    end
  end
end
