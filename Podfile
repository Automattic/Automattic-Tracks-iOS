source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!
use_frameworks!
project 'Automattic-Tracks-iOS.xcodeproj'

def shared
  pod 'CocoaLumberjack', '~> 3'
  pod 'Reachability', '~> 3'
  pod 'Sentry', '~> 5'
  pod 'Sodium', '~> 0.8.0'
end

target 'Automattic-Tracks-iOS' do
  platform :ios, '9.0'
  shared
  pod 'UIDeviceIdentifier', '~> 1'
end

target 'Automattic-Tracks-OSX' do
  platform :osx, '10.11'
  shared
end

def test_shared
  pod 'OCMock', '~> 3'
  pod 'OHHTTPStubs'
  pod 'OHHTTPStubs/Swift'
end

target 'Automattic-Tracks-iOSTests' do
  platform :ios, '9.0'
  test_shared
end

target 'Automattic_Tracks_OSXTests' do
  platform :osx, '10.11'
  test_shared
end
