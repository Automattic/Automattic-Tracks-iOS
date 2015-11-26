Pod::Spec.new do |spec|
  spec.name         = 'Automattic-Tracks-OSX'
  spec.version      = File.read("Automattic-Tracks-iOS/TracksConstants.m").split("const TracksLibraryVersion = @\"").last.split("\"").first
  spec.platform     = :osx, "10.8"
  spec.license      = { :type => 'GPLv2' }
  spec.homepage     = 'https://github.com/automattic/automattic-tracks-ios'
  spec.authors      = { 'Aaron Douglas' => 'aaron@automattic.com' }
  spec.summary      = 'Simple way to track events in an iOS app with Automattic Tracks internal service'
  spec.source       = { :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => spec.version.to_s }
  spec.source_files = 'Automattic-Tracks-iOS/**/*.{h,m}'
  spec.resource_bundle = { 'DataModel' => ['Automattic-Tracks-iOS/**/*.xcdatamodeld'] }
  spec.framework    = 'CoreData'

  spec.dependency 'CocoaLumberjack', '~>2.2.0'
  spec.dependency 'Reachability', '~>3.1'
end
