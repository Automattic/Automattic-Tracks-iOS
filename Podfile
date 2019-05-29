inhibit_all_warnings!
use_modular_headers!
project 'Automattic-Tracks-iOS.xcodeproj'

abstract_target 'Automattic-Tracks' do
  pod 'CocoaLumberjack', '~> 3.5.2'
  pod 'Reachability', '~> 3.1'

  target 'Automattic-Tracks-iOS' do
    platform :ios, '9.0'
    pod 'UIDeviceIdentifier', '~> 1.1.4'
  end

  target 'Automattic-Tracks-OSX' do
    platform :osx, '10.11'
  end
end

abstract_target 'Automattic-Tracks-Tests' do
  pod 'OCMock', '~> 3.4.3'
  pod 'OHHTTPStubs'
  pod 'OHHTTPStubs/Swift'

  target 'Automattic-Tracks-iOSTests' do
    platform :ios, '9.0'
  end

  target 'Automattic_Tracks_OSXTests' do
    platform :osx, '10.11'
  end
end
