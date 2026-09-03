# frozen_string_literal: true

require_relative "secretsweep/version"
require_relative "secretsweep/entropy"
require_relative "secretsweep/pattern_registry"
require_relative "secretsweep/finding"
require_relative "secretsweep/ignore_list"
require_relative "secretsweep/file_scanner"
require_relative "secretsweep/git_history_scanner"
require_relative "secretsweep/reporter"
require_relative "secretsweep/scanner"
require_relative "secretsweep/cli"

module SecretSweep
  class Error < StandardError; end
end
