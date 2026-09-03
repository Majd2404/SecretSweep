# frozen_string_literal: true

require "test_helper"

class EntropyTest < Minitest::Test
  def test_empty_string_has_zero_entropy
    assert_equal 0.0, SecretSweep::Entropy.shannon("")
  end

  def test_repeated_character_has_zero_entropy
    assert_equal 0.0, SecretSweep::Entropy.shannon("aaaaaaaaaa")
  end

  def test_random_looking_string_has_high_entropy
    random_ish = "aB3$kL9#mN2@pQ7!"
    assert SecretSweep::Entropy.shannon(random_ish) > 3.0
  end

  def test_high_entropy_rejects_short_strings_regardless_of_randomness
    refute SecretSweep::Entropy.high_entropy?("aB3$", min_length: 20)
  end

  def test_high_entropy_accepts_long_random_looking_token
    token = "sk_9fK2mN8pQ4rS7tU1vW3xY6zA0bC5dE"
    assert SecretSweep::Entropy.high_entropy?(token)
  end

  def test_high_entropy_rejects_long_but_low_entropy_text
    text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    refute SecretSweep::Entropy.high_entropy?(text)
  end

  def test_nil_input_does_not_raise
    assert_equal 0.0, SecretSweep::Entropy.shannon(nil)
    refute SecretSweep::Entropy.high_entropy?(nil)
  end
end
