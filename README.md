# SecretSweep

**A dependency-free Ruby CLI that scans files and full git history for leaked secrets — API keys, tokens, private keys — using known-format patterns plus entropy analysis for everything else.**

![Ruby](https://img.shields.io/badge/Ruby-3.0%2B-CC342D?logo=ruby&logoColor=white)
![Dependencies](https://img.shields.io/badge/runtime_deps-zero-brightgreen)
![Tests](https://img.shields.io/badge/tests-36_passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

## Why this exists

Secrets leak into git repos constantly — a hardcoded API key committed
"just for testing," a `.env` file that wasn't gitignored in time. The
sneaky part: **removing the secret in the next commit does not remove it
from git history.** Anyone with `git log -p` can still read it. This tool
scans both the working tree and full history, and treats them as equally
important.

## How it works

Two independent detection layers, deliberately kept separate:

1. **Pattern matching** (`PatternRegistry`) — known formats: AWS keys,
   GitHub/Slack/Stripe tokens, PEM private key headers, JWTs, and a
   generic `key = "..."` assignment heuristic.
2. **Entropy analysis** (`Entropy`) — Shannon entropy per character.
   Catches secrets in formats with no dedicated pattern yet (a new
   provider, an internal auth token) by flagging strings that are
   "suspiciously random" rather than matching a specific shape.

Both layers can flag the *same* secret independently — see
[Known limitations](#known-limitations) below for why that's left as-is
rather than "fixed."

## Installation

```bash
git clone https://github.com/yourusername/SecretSweep.git
cd SecretSweep
bundle install
gem build secretsweep.gemspec
gem install ./secretsweep-0.1.0.gem
```

## Usage

```bash
# Scan the current directory's working tree
secretsweep .

# Also scan full git history (every branch)
secretsweep . --history

# Machine-readable output, e.g. for CI
secretsweep . --format json

# Use a specific ignore file
secretsweep . --ignore-file .secretsweepignore
```

Exit codes: `0` = clean, `1` = secrets found, `2` = error (e.g. not a git
repo when `--history` was requested).

### Example output

```
$ secretsweep . --history
Found 1 potential secret(s):

  [aws_access_key_id] config.rb @ 010f580376fd
    AKIA...MPLE  (fingerprint: 039a924b0920)

To allowlist a confirmed false positive, add its fingerprint to .secretsweepignore
```

That example is real — it's what `secretsweep` reports against a test
repo where an AWS key was committed and then "removed" in a later
commit. The removal didn't help; the key is still readable in history.

### Ignoring false positives

Copy `.secretsweepignore.example` to `.secretsweepignore` in the
directory you're scanning. Two kinds of entries:

```
# Skip scanning these paths entirely
test/fixtures/**

# Allowlist ONE specific confirmed false positive by its fingerprint
# (does NOT silence the whole rule — just that exact file+type+snippet)
a1b2c3d4e5f6
```

## Design decisions worth reading

- **Two detection layers, kept intentionally separate.** Pattern
  matching and entropy analysis never share code — a bug in one can't
  silently break the other, and each is independently testable.
- **Fingerprints, not line numbers, are the identity of a finding.**
  A fingerprint is a hash of `source:type:snippet` — it survives the
  file being edited above the secret, so an ignore-list entry doesn't
  silently stop working the next time someone touches that file.
- **The ignore list has two granularities on purpose.** A path glob
  silences a whole directory (fixtures, generated files); a fingerprint
  silences exactly one confirmed false positive. Collapsing these into
  one mechanism would force a choice between "too broad" and "too
  narrow" for different real situations.
- **Git history scanning shells out to the real `git` binary** rather
  than reimplementing pack-file parsing or depending on a native
  extension gem — `git log -p --all` is well-tested, always available
  wherever git itself is, and the output format is stable.
- **Zero runtime dependencies.** The whole tool is Ruby stdlib
  (`optparse`, `json`, `open3`, `digest`, `pathname`, `find`). Anyone can
  `gem install` it with no dependency resolution at all.

## Known limitations

- **The same secret can be reported twice**, once by pattern matching
  and once by entropy analysis, if it happens to satisfy both (e.g. a
  GitHub token is both a recognized format *and* high-entropy). This is
  left as-is rather than deduplicated across types: two independent
  detectors agreeing is a legitimate confidence signal, and collapsing
  it would hide which detector(s) actually fired. See
  `docs/COMMIT_PLAN.md` for a possible future confidence-scoring
  approach instead of outright deduplication.
- **Entropy thresholds are heuristic**, not universally tuned — see
  `docs/COMMIT_PLAN.md` Week 2 for the plan to validate them against a
  larger real-world sample.
- **History scanning reads the full diff of every commit on every
  branch** (`git log -p --all`) — this is thorough but can be slow on
  very large, long-lived repositories. No pagination/depth limit yet.

## Testing

```bash
rake test
```

36 tests, zero dependencies beyond Ruby's bundled Minitest — no network
access or external services required to run the suite. Includes a real
integration test (`git_history_scanner_test.rb`) that creates an actual
throwaway git repo, commits a secret, removes it in a later commit, and
verifies `--history` still catches it.

## Roadmap

See [`docs/COMMIT_PLAN.md`](docs/COMMIT_PLAN.md) for the week-by-week build-out plan.

## Tech stack

Ruby 3.0+, standard library only. Minitest + Rake for testing.

## License

MIT — see [LICENSE](LICENSE).
