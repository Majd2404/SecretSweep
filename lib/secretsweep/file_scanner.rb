# frozen_string_literal: true

require "find"
require "pathname"

module SecretSweep
  # Scans the current state of files on disk (as opposed to GitHistoryScanner,
  # which scans past commits). Skips binary files and common noise
  # directories so a full repo scan doesn't choke on node_modules or .git
  # internals.
  class FileScanner
    SKIP_DIRS = %w[.git node_modules vendor tmp log dist build coverage .bundle].freeze
    MAX_FILE_SIZE = 2 * 1024 * 1024 # 2MB — skip huge files (logs, binaries, lockfiles)

    def initialize(root, ignore_list: IgnoreList.new([], []))
      @root = root
      @ignore_list = ignore_list
    end

    def scan
      findings = []

      each_scannable_file do |path|
        relative_path = relative(path)
        next if @ignore_list.path_ignored?(relative_path)

        findings.concat(scan_file(path, relative_path))
      end

      findings
    end

    private

    def each_scannable_file
      Find.find(@root) do |path|
        if File.directory?(path)
          Find.prune if SKIP_DIRS.include?(File.basename(path))
          next
        end
        next unless File.file?(path)
        next if File.size(path) > MAX_FILE_SIZE
        next if binary?(path)

        yield path
      end
    end

    def scan_file(path, relative_path)
      findings = []

      File.foreach(path).with_index(1) do |line, line_number|
        # Guard per-line, not per-file: one malformed line (bad encoding,
        # unexpected control characters) should never discard matches
        # already found earlier in the same file.
        begin
          PatternRegistry.scan_line(line).each do |match|
            findings << Finding.new(relative_path, line_number, match[:type], match[:snippet], nil)
          end
          check_high_entropy_tokens(line, relative_path, line_number, findings)
        rescue ArgumentError, Encoding::InvalidByteSequenceError
          next
        end
      end

      findings
    rescue ArgumentError, Encoding::InvalidByteSequenceError, Errno::ENOENT
      # File wasn't actually readable/valid text despite passing the
      # binary? heuristic (e.g. removed between listing and reading).
      findings
    end

    # Beyond known patterns, flag bare high-entropy tokens assigned to a
    # variable — catches secrets in formats we don't have a specific regex
    # for yet (a new provider's token format, an internal auth token).
    def check_high_entropy_tokens(line, relative_path, line_number, findings)
      return unless line.match?(/=|:/)

      line.scan(/['"]([A-Za-z0-9\/+_-]{20,})['"]/) do |match|
        token = match[0]
        next unless Entropy.high_entropy?(token)

        findings << Finding.new(relative_path, line_number, "high_entropy_string", token, nil)
      end
    end

    def relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
    end

    def binary?(path)
      sample = File.open(path, "rb") { |f| f.read(512) }
      return false if sample.nil?

      sample.include?("\x00")
    end
  end
end
