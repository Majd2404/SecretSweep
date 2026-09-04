# frozen_string_literal: true

# NOTE: every "secret" in this file is fake/invalid, used only to test
# that SecretSweep's pattern matching works. None of these are real.

AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
GITHUB_TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyz12"

def stripe_config
  { secret_key: "sk_test_51NqA9K2mP8vQ3xR7tY6wZ0bC4dE" }
end

# This one should be ignored — placeholder hint present
API_KEY = "your_api_key_goes_here_xxxxxxxxxxxxxxxx"

# Ordinary code, should never be flagged
def add(a, b)
  a + b
end
