# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2026-09-09

### Added

- GitHub Actions CI workflow (`.github/workflows/ci.yml`) running RSpec, Rubocop, and RBS signature validation on every push and pull request, across Ruby 3.0–3.3.
- `metadata` in the gemspec (`homepage_uri`, `source_code_uri`, `changelog_uri`, `bug_tracker_uri`) for better discoverability on RubyGems.org.

### Fixed

- Gemspec development dependencies corrected: `rspec` and `rbs` replace the stale `minitest` reference left over from the pre-migration scaffold.
- `sig/**/*.rbs` and `CHANGELOG.md` are now actually included in the packaged gem — previous versions omitted the type signatures entirely despite them existing in the repo.

## [0.1.1] - 2026-09-07

### Fixed

- Corrected the homepage/source code URL in `secretsweep.gemspec` to point to the actual GitHub repository.

## [0.1.0] - 2026-09-05

### Added

- Core secret-detection engine combining two independent methods:
  - Pattern matching (`PatternRegistry`) for known formats: AWS keys, GitHub/Slack/Stripe tokens, PEM private key headers, Google API keys, JWTs, and a generic key-assignment heuristic.
  - Shannon entropy analysis (`Entropy`) to catch high-entropy strings that don't match any known format.
- `FileScanner` — scans a directory tree for secrets in the current working tree, skipping binary files and common noise directories (`node_modules`, `.git`, `vendor`, etc.).
- `GitHistoryScanner` — scans full git history across all branches (`git log -p --all`) to catch secrets that were committed and later removed but are still readable in history.
- `IgnoreList` / `.secretsweepignore` support with two levels of granularity: path globs (skip a directory entirely) and per-finding fingerprints (allowlist one confirmed false positive without silencing the whole rule).
- Stable, content-based fingerprinting (`Finding#fingerprint`) so ignore-list entries survive unrelated edits to the same file.
- CLI (`bin/secretsweep`) with `--history`, `--format [text|json]`, and `--ignore-file` flags, and meaningful exit codes (0 clean / 1 secrets found / 2 error).
- Text and JSON report output via `Reporter`.
- Full RSpec test suite (37 examples), including an end-to-end test that creates a real throwaway git repo, commits a secret, removes it in a later commit, and verifies history scanning still finds it.
- RBS type signatures for the full public API.
- Zero runtime dependencies — pure Ruby standard library (`optparse`, `json`, `open3`, `digest`, `pathname`, `find`).

### Known limitations

- The same secret can be reported twice (once per detection method) if it satisfies both pattern matching and entropy analysis. This is intentional — see README for reasoning.
- Entropy thresholds are heuristic, not yet validated against a large real-world sample.