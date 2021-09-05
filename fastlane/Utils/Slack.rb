
def broadcast_message()
  version = get_info_plist_value(
    path: "#{APP_NAME}/Info.plist",
    key: "CFBundleShortVersionString"
  )
  
  
  build = get_info_plist_value(
    path: "#{APP_NAME}/Info.plist",
    key: "CFBundleVersion"
  )

  slack(
    message: "Hi! A new iOS build has been submitted to TestFlight",
    payload: {
      "Build Date" => Time.new.to_s,
      "Release Version" => version+"."+build
    },
    slack_url: SLACK_CHANNEL,
    use_webhook_configured_username_and_icon: true,
    fail_on_error: false,
    success: true
  ) 
end

def on_error(exception)
  slack(
    message: exception.to_s,
    slack_url: SLACK_CHANNEL,
    success: false,
    payload: { "Output" => exception.to_s },
    fail_on_error: true
  )
end 