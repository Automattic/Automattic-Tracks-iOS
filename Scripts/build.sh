if [ ! $TRAVIS ]; then
TRAVIS_XCODE_WORKSPACE=Automattic-Tracks-iOS.xcworkspace
TRAVIS_XCODE_PROJECT=Automattic-Tracks-iOS.xcodeproj
TRAVIS_XCODE_SCHEME=Automattic-Tracks-iOS
TRAVIS_XCODE_SDK=iphonesimulator
fi

xcodebuild build test \
-workspace "$TRAVIS_XCODE_WORKSPACE" \
-scheme "$TRAVIS_XCODE_SCHEME" \
-sdk "$TRAVIS_XCODE_SDK" \
-destination "name=iPhone SE" \
-configuration Debug | xcpretty -c

pod spec lint --allow-warnings

exit ${PIPESTATUS[0]}

