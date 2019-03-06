XCODE_WORKSPACE=Automattic-Tracks-iOS.xcworkspace
XCODE_PROJECT=Automattic-Tracks-iOS.xcodeproj
XCODE_SCHEME=Automattic-Tracks-iOS
XCODE_SDK=iphonesimulator

xcodebuild build test \
-workspace "$XCODE_WORKSPACE" \
-scheme "$XCODE_SCHEME" \
-sdk "$XCODE_SDK" \
-destination "name=iPhone SE" \
-configuration Debug | bundle exec xcpretty -c

bundle exec pod lib lint

exit ${PIPESTATUS[0]}

