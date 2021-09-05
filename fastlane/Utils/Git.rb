def git_changelog()
  changelog_from_git_commits(
    between: ["main", "origin/develop"],
    pretty: "- %s",
    date_format: "short",
    match_lightweight_tag: false, 
    merge_commit_filtering: "exclude_merges" 
  ) || []
end