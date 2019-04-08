# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

inhibit_all_warnings!
use_frameworks!

target 'Automattic-Tracks-iOS' do
  platform :ios, '9.0'

  pod 'UIDeviceIdentifier', '~> 1.1.4'
  pod 'CocoaLumberjack', '~> 3.4.1'
  pod 'Reachability', '~> 3.1'

  target 'Automattic-Tracks-iOSTests' do
    pod 'OCMock', '~> 3.3.1'
    pod 'OHHTTPStubs'
    pod 'OHHTTPStubs/Swift'
  end
end

target 'Automattic-Tracks-OSX' do
    platform :osx, '10.11'

    pod 'CocoaLumberjack', '~> 3.4.1'
    pod 'Reachability', '~> 3.1'

  target 'Automattic_Tracks_OSXTests' do
    pod 'OCMock', '~> 3.3.1'
    pod 'OHHTTPStubs'
    pod 'OHHTTPStubs/Swift'
  end

end
