Pod::Spec.new do |s|
  s.name          = 'Automattic-Tracks-iOS'
  s.version       = '0.9.0'

  s.summary       = 'Simple way to track events in an iOS app with Automattic Tracks internal service'
  s.description   = <<-DESC
                    This framework provides an abstract layer on our Automattic Tracks internal analytics service,
                    and allows to easily send events to Tracks to monitor our app's activity and flows.
                  DESC

  s.homepage      = 'https://github.com/Automattic/Automattic-Tracks-iOS'
  s.license       = { :type => 'GPLv2', :file => 'LICENSE' }
  s.author        = { 'Automattic' => 'mobile@automattic.com' }
  s.social_media_url = 'https://twitter.com/automattic'

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.12'
  s.swift_version = '5.0'

  s.source        = { :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => s.version.to_s }
  s.ios.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  s.ios.exclude_files = 'Automattic-Tracks-OSX/Automattic_Tracks_OSX.h'
  s.osx.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  s.osx.exclude_files = ['Automattic-Tracks-iOS/Automattic-Tracks-iOS.h', 'Automattic-Tracks-iOS/ABTesting/*']

  s.private_header_files = 'Automattic-Tracks-iOS/Internal Logging/TracksLoggingPrivate.h'
  s.resource_bundle = { 'DataModel' => ['Automattic-Tracks-iOS/**/*.xcdatamodeld'] }

  s.framework        = 'CoreData'
  s.ios.framework    = 'UIKit'
  s.ios.framework    = 'CoreTelephony'
  s.osx.framework    = 'AppKit'

  s.header_dir = 'AutomatticTracks'
  s.module_name = 'AutomatticTracks'

  s.ios.dependency 'UIDeviceIdentifier', '~> 1'
  s.dependency 'CocoaLumberjack', '~> 3'
  s.dependency 'Reachability', '~> 3'
  s.dependency 'Sentry', '~> 6'
  s.dependency 'Sodium', '>= 0.9.1'
end
