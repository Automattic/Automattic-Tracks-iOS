Pod::Spec.new do |spec|
  spec.name         = 'Automattic-Tracks-iOS'
  spec.version      = File.read("Automattic-Tracks-iOS/TracksConstants.m").split("const TracksLibraryVersion = @\"").last.split("\"").first
  spec.license      = { :type => 'GPLv2' }
  spec.homepage     = 'https://github.com/automattic/automattic-tracks-ios'
  spec.authors      = { 'Automattic' => 'mobile@automattic.com' }
  spec.summary      = 'Simple way to track events in an iOS app with Automattic Tracks internal service'
  spec.source       = { :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => spec.version.to_s }
  spec.swift_version = '4.2'

  spec.ios.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  spec.ios.exclude_files = 'Automattic-Tracks-OSX/Automattic_Tracks_OSX.h'

  spec.osx.source_files = 'Automattic-Tracks-iOS/**/*.{h,m,swift}'
  spec.osx.exclude_files = 'Automattic-Tracks-iOS/Automattic-Tracks-iOS.h'

  spec.private_header_files = 'Automattic-Tracks-iOS/Private/*.h'
  spec.resource_bundle = { 'DataModel' => ['Automattic-Tracks-iOS/**/*.xcdatamodeld'] }

  spec.framework        = 'CoreData'
  spec.ios.framework    = 'UIKit'
  spec.ios.framework    = 'CoreTelephony'
  spec.osx.framework    = 'AppKit'

  spec.ios.deployment_target  = '9.3'
  spec.osx.deployment_target  = '10.11'

  spec.header_dir = 'AutomatticTracks'
  spec.module_name = 'AutomatticTracks'

  spec.ios.dependency 'UIDeviceIdentifier', '~> 1.1.4'
  spec.dependency 'CocoaLumberjack', '~> 3.5.2'
  spec.dependency 'Reachability', '~>3.1'
  spec.dependency 'Sentry', '~>4'
end
