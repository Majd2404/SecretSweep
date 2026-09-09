# frozen_string_literal: true

require "optparse"

module SecretSweep
  # Thin CLI wrapper. Deliberately kept dumb — argument parsing and exit
  # codes only, no scanning logic — so Scanner/FileScanner/etc. stay
  # usable as a plain Ruby library, e.g. `require "secretsweep"` inside
  # a Rake task, with no CLI involved at all.
  class CLI
    EXIT_CLEAN = 0
    EXIT_SECRETS_FOUND = 1
    EXIT_ERROR = 2

    def self.start(argv)
      new.run(argv)
    end

    def run(argv)
      options = parse(argv)
      findings = scan(options)

      puts Reporter.render(findings, format: options[:format])
      findings.empty? ? EXIT_CLEAN : EXIT_SECRETS_FOUND
    rescue GitHistoryScanner::NotAGitRepoError, Errno::ENOENT => e
      warn "Error: #{e.message}"
      EXIT_ERROR
    end

    private

    def scan(options)
      path = options[:path] || "."
      Scanner.new(path, ignore_file: options[:ignore_file], include_history: options[:history]).run
    end

    def parse(argv)
      options = { format: :text, history: false }
      parser = build_option_parser(options)

      remaining = parser.parse(argv)
      options[:path] = remaining.first
      options
    end

    def build_option_parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: secretsweep [path] [options]"

        opts.on("--history", "Also scan full git history, not just the working tree") do
          options[:history] = true
        end

        opts.on("--format FORMAT", %w[text json], "Output format: text (default) or json") do |fmt|
          options[:format] = fmt.to_sym
        end

        opts.on("--ignore-file PATH", "Path to a .secretsweepignore file (default: <path>/.secretsweepignore)") do |p|
          options[:ignore_file] = p
        end

        opts.on("-v", "--version", "Print the version and exit") do
          puts SecretSweep::VERSION
          exit(0)
        end

        opts.on("-h", "--help", "Print this help") do
          puts opts
          exit(0)
        end
      end
    end
  end
end
