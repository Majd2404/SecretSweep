# frozen_string_literal: true

require "open3"

module SecretSweep
  # Scans git history — not just the working tree — because a secret
  # deleted in the latest commit is still fully readable by anyone who
  # runs `git log -p` or `git show <old-sha>`. This is the check that
  # catches "I removed the key in the next commit" as still a real leak.
  class GitHistoryScanner
    class NotAGitRepoError < StandardError; end

    # Tracks the small bit of state needed while walking `git log -p`
    # output line by line: which commit and file we're currently inside,
    # plus the findings accumulated so far. Extracted from Scanner so
    # #scan itself stays a short, readable dispatch loop.
    State = Struct.new(:commit, :file, :findings) do
      def initialize
        super(nil, nil, [])
      end
    end

    def initialize(repo_path, ignore_list: IgnoreList.new([], []))
      @repo_path = repo_path
      @ignore_list = ignore_list
    end

    def scan
      raise NotAGitRepoError, "#{@repo_path} is not a git repository" unless git_repo?

      state = State.new
      each_diff_line { |line| process_line(line, state) }
      state.findings
    end

    private

    def process_line(line, state)
      case line
      when /\Acommit /
        state.commit = line.split(" ", 2).last[0, 12]
      when %r{\A\+\+\+ b/}
        state.file = line.sub("+++ b/", "").strip
      when /\A\+(?!\+\+)/
        record_added_line(line[1..], state)
      end
    end

    def record_added_line(content, state)
      return if state.file.nil? || @ignore_list.path_ignored?(state.file)

      PatternRegistry.scan_line(content).each do |match|
        state.findings << Finding.new(state.file, nil, match[:type], match[:snippet], state.commit)
      end
    end

    def git_repo?
      _out, status = Open3.capture2("git", "-C", @repo_path, "rev-parse", "--is-inside-work-tree")
      status.success?
    end

    def each_diff_line(&block)
      # -p: show patches (actual added/removed lines), --all: every branch,
      # not just the currently checked-out one — a secret on a stale
      # feature branch is still a leak.
      Open3.popen2("git", "-C", @repo_path, "log", "-p", "--all", "--no-color") do |_in, out, _thread|
        out.each_line(&block)
      end
    end
  end
end
