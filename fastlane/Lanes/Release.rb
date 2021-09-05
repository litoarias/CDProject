lane :release do |lane|

  begin

    if !lane[:bump]
      raise Exception.new "No bump type defined! Use one of: patch | minor | major".red
    end

    # Temporay keychain creation
    ensure_temp_keychain(TEMP_KEYCHAIN_USER, TEMP_KEYCHAIN_PASSWORD)
    
    # the semantic version added
    type = lane[:bump]

    increment_version_number(
      bump_type: type # Automatically increment patch version number
    )
    
    # increment build number
    increment_build_number

    # Connect to App Store Connect
    api_key = app_store_connect_api_key(
      key_id: APPLE_KEY_ID,
      issuer_id: APPLE_ISSUER_ID,
      key_content: APPLE_KEY_CONTENT,            
      duration: 1200,            
      in_house: false
    )

    # Signin step
    match(
      type: 'appstore',
      app_identifier: "#{DEVELOPER_APP_IDENTIFIER}",
      git_basic_authorization: Base64.strict_encode64("#{GIT_USER}:#{GIT_AUTHORIZATION}"),
      readonly: true,
      keychain_name: TEMP_KEYCHAIN_USER,
      keychain_password: TEMP_KEYCHAIN_PASSWORD,
      api_key: api_key
    )

    # Make IPA
    gym(
      configuration: "Release",
      scheme: SCHEME,
      export_method: "app-store",
      export_options: {
        provisioningProfiles: { 
          DEVELOPER_APP_ID => PROVISIONING_PROFILE_SPECIFIER
        }
      }
    )

    # Transport and deploy to App Store Connect
    pilot(
      apple_id: "#{DEVELOPER_APP_ID}",
      app_identifier: "#{DEVELOPER_APP_IDENTIFIER}",
      skip_waiting_for_build_processing: true,
      skip_submission: true,
      distribute_external: false,
      notify_external_testers: false,
      ipa: "./#{APP_NAME}.ipa"
    )

    # Send successfully upload binary message
    broadcast_message
    
    # Remove temporary keychain
    delete_temp_keychain(TEMP_KEYCHAIN_USER)

    version = get_version_number
    
    # Publish tag and release on Github
    # creates a bump version commit 
    commit_version_bump(
      message: "Version bumped to v#{version}"
    )


    # push bump commit
    push_to_git_remote(
      tags: false
    )

    # get the last commit comments from Git history
    # and creates our changelog
    comments = git_changelog

    # create a local tag with the new version
    add_git_tag(
      message: comments
    )   

    # publish a new release into Github
    github_release = set_github_release(
        api_token: GIT_AUTHORIZATION,
        repository_name: "litoarias/CDProject",
        name: "#{type.capitalize} version v#{version}",
        tag_name: "v#{version}",
        description: comments,
        commitish: "main"
    )

  rescue => exception
    on_error(exception)
  end
  
end