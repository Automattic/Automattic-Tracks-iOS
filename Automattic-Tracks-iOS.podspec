Pod::Spec.new do |spec|
  spec.name         = 'Automattic-Tracks-iOS'
  spec.version      = File.read("Automattic-Tracks-iOS/TracksConstants.m").split("const TracksLibraryVersion = @\"").last.split("\"").first
  spec.license      = { :type => 'GPLv2' }
  spec.homepage     = 'https://github.com/automattic/automattic-tracks-ios'
  spec.authors      = { 'Automattic' => 'mobile@automattic.com' }
  spec.summary      = 'Simple way to track events in an iOS app with Automattic Tracks internal service'
  spec.source       = { :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => spec.version.to_s }
  spec.swift_version = '5.0'

  spec.ios.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  spec.ios.exclude_files = 'Automattic-Tracks-OSX/Automattic_Tracks_OSX.h'

  spec.osx.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  spec.osx.exclude_files = 'Automattic-Tracks-iOS/Automattic-Tracks-iOS.h'

  spec.private_header_files = 'Automattic-Tracks-iOS/Internal Logging/TracksLoggingPrivate.h'
  spec.resource_bundle = { 'DataModel' => ['Automattic-Tracks-iOS/**/*.xcdatamodeld'] }

  spec.framework        = 'CoreData'
  spec.ios.framework    = 'UIKit'
  spec.ios.framework    = 'CoreTelephony'
  spec.osx.framework    = 'AppKit'

  spec.ios.deployment_target  = '12.0'
  spec.osx.deployment_target  = '10.11'

  spec.header_dir = 'AutomatticTracks'
  spec.module_name = 'AutomatticTracks'

  spec.ios.dependency 'UIDeviceIdentifier', '~> 1'
  spec.dependency 'CocoaLumberjack', '~> 3'
  spec.dependency 'Reachability', '~> 3'
  spec.dependency 'Sentry', '~>4'
  spec.dependency 'Sodium', '~> 0.9'

  # Xcode 12 changed the way apps are built because of the upcoming support for
  # Apple Silicon. We need explicitly exclude the arm64 architecture.
  # More info at
  # https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
  }

  # Notice that a CocoaPods contributor discourages the use of
  # `user_target_xcconfig`, but in this case also agrees that there might not be
  # a better approach.
  # See
  # https://github.com/CocoaPods/CocoaPods/issues/10065#issuecomment-701055569
  spec.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
  }
end
