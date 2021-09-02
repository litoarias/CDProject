def git_changelog()
  changelog_from_git_commits(
    between: ["main", "origin/develop"],
    pretty: "- %s",
    date_format: "short",
    match_lightweight_tag: false, 
    merge_commit_filtering: "exclude_merges" 
  ) || []
end


def git_semantic_versioning(old, type)

  version = old

  old[0] = ''
  oldArr = old.split('.').map{|v| v.to_i}    

  if type == "patch"
      version = "#{oldArr[0]}.#{oldArr[1]}.#{oldArr[2] + 1}"
  elsif type == "minor"
      version = "#{oldArr[0]}.#{oldArr[1] + 1}.0"
  elsif type == "major"
      version = "#{oldArr[0] + 1}.0.0"
  end   
  
  if version == old
      UI.user_error!("Wrong release type parameter. Enter: patch | minor | major")
  end
  version
end