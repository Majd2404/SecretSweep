# frozen_string_literal: true

require "open3"

module SecretSweep
  # Scans git history — not just the working tree — because a secret
  # deleted in the latest commit is still fully readable by anyone who
  # runs `git log -p` or `git show <old-sha>`. This is the check that
  # catches "I removed the key in the next commit" as still a real leak.
  class GitHistoryScanner
    class NotAGitRepoError < StandardError; end

    def initialize(repo_path, ignore_list: IgnoreList.new([], []))
      @repo_path = repo_path
      @ignore_list = ignore_list
    end

    def scan
      raise NotAGitRepoError, "#{@repo_path} is not a git repository" unless git_repo?

      findings = []
      current_file = nil
      current_commit = nil

      each_diff_line do |line|
        if line.start_with?("commit ")
          current_commit = line.split(" ", 2).last[0, 12]
        elsif line.start_with?("+++ b/")
          current_file = line.sub("+++ b/", "").strip
        elsif line.start_with?("+") && !line.start_with?("+++")
          content = line[1..]
          next if current_file.nil? || @ignore_list.path_ignored?(current_file)

          PatternRegistry.scan_line(content).each do |match|
            findings << Finding.new(current_file, nil, match[:type], match[:snippet], current_commit)
          end
        end
      end

      findings
    end

    private

    def git_repo?
      _out, status = Open3.capture2("git", "-C", @repo_path, "rev-parse", "--is-inside-work-tree")
      status.success?
    end

    def each_diff_line
      # -p: show patches (actual added/removed lines), --all: every branch,
      # not just the currently checked-out one — a secret on a stale
      # feature branch is still a leak.
      Open3.popen2("git", "-C", @repo_path, "log", "-p", "--all", "--no-color") do |_in, out, _thread|
        out.each_line { |line| yield line }
      end
    end
  end
end
