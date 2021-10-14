private_lane :private_beta do

  begin
    
    # Ensure that your git status is not dirty
    ensure_git_status_clean

    # increment build number
    increment_build_number(xcodeproj: "#{APP_NAME}.xcodeproj")
    
    # Temporay keychain creation
    ensure_temp_keychain(TEMP_KEYCHAIN_USER, TEMP_KEYCHAIN_PASSWORD)

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

    # Transport and deploy to testflight
    pilot(
      apple_id: "#{DEVELOPER_APP_ID}",
      app_identifier: "#{DEVELOPER_APP_IDENTIFIER}",
      skip_waiting_for_build_processing: true,
      skip_submission: true,
      distribute_external: false,
      notify_external_testers: false,
      ipa: "./#{APP_NAME}.ipa"
    )

    # Successful message slack
    broadcast_message

    # Commit the version bump
    commit_version_bump(xcodeproj: "#{APP_NAME}.xcodeproj")

    # Push the new commit and tag back to your git remote
    push_to_git_remote

    # Remove temporary keychain
    delete_temp_keychain(TEMP_KEYCHAIN_USER)

  rescue => exception
    puts exception.to_s
    on_error(exception)
  end

end