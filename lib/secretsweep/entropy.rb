# frozen_string_literal: true

module SecretSweep
  # Computes Shannon entropy of a string — a measure of "randomness" per
  # character, in bits. Real secrets (API keys, tokens) tend to be
  # high-entropy (close to random); English words, file paths, and normal
  # code tend to be low-entropy. This catches secrets that don't match any
  # known regex pattern — a purely regex-based scanner misses those.
  module Entropy
    module_function

    def shannon(str)
      return 0.0 if str.nil? || str.empty?

      frequencies = Hash.new(0)
      str.each_char { |c| frequencies[c] += 1 }

      length = str.length
      frequencies.values.reduce(0.0) do |entropy, count|
        probability = count.to_f / length
        entropy - (probability * Math.log2(probability))
      end
    end

    # A candidate string is "suspiciously random" if its entropy per
    # character exceeds this threshold. Tuned empirically: base64-like
    # secrets tend to sit around 4.0-4.5 bits/char; English text sits
    # around 3.5-4.0 for lowercase-heavy content but real code identifiers
    # (snake_case, camelCase) tend lower still.
    DEFAULT_THRESHOLD = 4.3

    def high_entropy?(str, threshold: DEFAULT_THRESHOLD, min_length: 20)
      return false if str.nil? || str.length < min_length

      shannon(str) >= threshold
    end
  end
end
