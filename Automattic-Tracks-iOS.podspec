Pod::Spec.new do |spec|
  spec.name         = 'Automattic-Tracks-iOS'
  spec.version      = File.read("Automattic-Tracks-iOS/TracksConstants.m").split("const TracksLibraryVersion = @\"").last.split("\"").first
  spec.platform     = :ios, "9.0"
  spec.license      = { :type => 'GPLv2' }
  spec.homepage     = 'https://github.com/automattic/automattic-tracks-ios'
  spec.authors      = { 'Automattic' => 'mobile@automattic.com' }
  spec.summary      = 'Simple way to track events in an iOS app with Automattic Tracks internal service'
  spec.source       = { :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => spec.version.to_s }
  spec.source_files = 'Automattic-Tracks-iOS/**/*.{h,m}'
  spec.private_header_files = 'Automattic-Tracks-iOS/Private/*.h'
  spec.resource_bundle = { 'DataModel' => ['Automattic-Tracks-iOS/**/*.xcdatamodeld'] }
  spec.framework    = 'CoreData'
  spec.framework    = 'CoreTelephony'

  spec.header_dir = 'AutomatticTracks'
  spec.module_name = 'AutomatticTracks'

  spec.dependency 'UIDeviceIdentifier', '~> 1.1.4'
  spec.dependency 'CocoaLumberjack', '~> 3.4.1'
  spec.dependency 'Reachability', '~>3.1'
end
