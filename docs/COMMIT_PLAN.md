# Build-out plan (for daily, real commits)

This scaffold already has working, tested code — 36 Minitest tests
passing, including a real end-to-end test against a throwaway git repo.
What's left is hardening and extending it. Each item below is a real,
committable unit of work.

## Week 1 — get comfortable with the codebase
- [ ] `bundle install`, run `rake test` locally, confirm all 36 pass
- [ ] `gem build secretsweep.gemspec && gem install ./secretsweep-0.1.0.gem`, run `secretsweep --help` for real
- [ ] Run `secretsweep --history` against one of your own old personal repos (a safe one!) and see what it finds
- [ ] Read through `pattern_registry.rb` and add one new provider pattern you actually use (Azure, GCP service account keys, Twilio, SendGrid, etc.)

## Week 2 — reduce false positives / false negatives
- [ ] Add a test case for a real false positive you hit in Week 1 and fix it
- [ ] Tune `Entropy::DEFAULT_THRESHOLD` against a larger sample of real vs. fake secrets, document your reasoning in the README
- [ ] Add support for `.env` file scanning with a dedicated pattern (KEY=value lines are a very common leak vector)
- [ ] Add a `--exclude-type` CLI flag to disable specific noisy rules per-run without needing a full ignore file

## Week 3 — CI integration
- [ ] Add a GitHub Actions workflow that runs `secretsweep .` on every push and fails the build on exit code 1
- [ ] Add SARIF output format so results show up natively in GitHub's Security tab
- [ ] Add a pre-commit hook example (`.git/hooks/pre-commit`) in the README showing how to block a commit containing a secret

## Week 4 — polish for public release
- [ ] Publish to RubyGems.org (`gem push`) so `gem install secretsweep` actually works for anyone
- [ ] Add a CHANGELOG.md following Keep a Changelog format
- [ ] Add badges for gem version + build status once CI is set up
- [ ] Write a short blog post / README section on the entropy vs. regex tradeoff — this is the part that shows real judgment, not just pattern-matching

## Ongoing
- [ ] Every new pattern added to `PatternRegistry` gets a test in `pattern_registry_test.rb` in the same commit — no exceptions, this is a security tool
- [ ] Keep the "known limitation" section of the README current as you fix things

Commit message style: `feat: ...`, `fix: ...`, `test: ...`, `docs: ...`.
