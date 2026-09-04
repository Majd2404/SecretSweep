# frozen_string_literal: true

require "spec_helper"

RSpec.describe SecretSweep::Entropy do
  describe ".shannon" do
    it "returns zero entropy for an empty string" do
      expect(described_class.shannon("")).to eq(0.0)
    end

    it "returns zero entropy for a repeated character" do
      expect(described_class.shannon("aaaaaaaaaa")).to eq(0.0)
    end

    it "returns higher entropy for a random-looking string" do
      random_ish = "aB3$kL9#mN2@pQ7!"
      expect(described_class.shannon(random_ish)).to be > 3.0
    end

    it "does not raise on nil input" do
      expect(described_class.shannon(nil)).to eq(0.0)
    end
  end

  describe ".high_entropy?" do
    it "rejects short strings regardless of randomness" do
      expect(described_class.high_entropy?("aB3$", min_length: 20)).to be(false)
    end

    it "accepts a long random-looking token" do
      token = "sk_9fK2mN8pQ4rS7tU1vW3xY6zA0bC5dE"
      expect(described_class.high_entropy?(token)).to be(true)
    end

    it "rejects long but low-entropy text" do
      text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      expect(described_class.high_entropy?(text)).to be(false)
    end

    it "does not raise on nil input" do
      expect(described_class.high_entropy?(nil)).to be(false)
    end
  end
end
