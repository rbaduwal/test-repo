#!/bin/bash
# This generates one ring to rule them all: a FAT .xcframework of both Q and Q.ui for all supported platforms and devices.
# You will need to manually edit the resulting script file if you want to code sign, although
# usually you don't need to because consumers will "Embed and Sign" within Xcode.
#
# This is intended to be run from the directory containing this script.

# Set to codesign each framework of the xcframework.
# Use your 10-character team identifier (you can find this in appstoreconnect).
MY_TEAM_ID=""

# Configure the build type for all frameworks in the xcframework
ARCHIVE_CONFIGURATION=Release

# ===================================================
# Shouldn't need to manually edit anything below this
# ===================================================

# Start fresh
xcodebuild -project Q/Q.xcodeproj -scheme Q clean
xcodebuild -project Q.ui/Q.ui.xcodeproj -scheme Q.ui clean
rm -rf Q.xcframework Q_ui.xcframework

# iOS device variant
ARCHIVE_IOS_PATH=ios
xcodebuild archive -project Q/Q.xcodeproj       -scheme Q    -configuration $ARCHIVE_CONFIGURATION -destination generic/platform=iOS -archivePath $ARCHIVE_IOS_PATH/Q.xcarchive -scmProvider xcode BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO
xcodebuild archive -project Q.ui/Q.ui.xcodeproj -scheme Q.ui -configuration $ARCHIVE_CONFIGURATION -destination generic/platform=iOS -archivePath $ARCHIVE_IOS_PATH/Q_ui.xcarchive                 BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO

# Mac OS Catalyst variant
#ARCHIVE_CAT_PATH=catalyst
#xcodebuild archive -project Q/Q.xcodeproj       -scheme Q    -configuration $ARCHIVE_CONFIGURATION -destination "platform=macOS,variant=Mac Catalyst" -archivePath $ARCHIVE_CAT_PATH/Q.xcarchive    -scmProvider xcode BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO
#xcodebuild archive -project Q.ui/Q.ui.xcodeproj -scheme Q.ui -configuration $ARCHIVE_CONFIGURATION -destination "platform=macOS,variant=Mac Catalyst" -archivePath $ARCHIVE_CAT_PATH/Q_ui.xcarchive                    BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO

# iOS simulator variant
#ARCHIVE_SIM_PATH=simulator
#xcodebuild archive -project Q/Q.xcodeproj       -scheme Q    -configuration $ARCHIVE_CONFIGURATION -sdk "iphonesimulator" -archivePath $ARCHIVE_SIM_PATH/Q.xcarchive    BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO
#xcodebuild archive -project Q.ui/Q.ui.xcodeproj -scheme Q.ui -configuration $ARCHIVE_CONFIGURATION -sdk "iphonesimulator" -archivePath $ARCHIVE_SIM_PATH/Q_ui.xcarchive BUILD_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO

# Codesign the individual frameworks (optional)
if [ ! -z "$MY_TEAM_ID" ]; then
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_IOS_PATH/Q.xcarchive
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_IOS_PATH/Q_ui.xcarchive
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_SIM_PATH/Q.xcarchive
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_SIM_PATH/Q_ui.xcarchive
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_CAT_PATH/Q.xcarchive
   codesign --verbose -s $MY_TEAM_ID $ARCHIVE_CAT_PATH/Q_ui.xcarchive
else
   echo "Not code signing, no team has been specified. If this is a mistake then please edit this script and try again"
fi

# Package all variants into a single .xcframework
xcodebuild -create-xcframework -output Q.xcframework    -framework $ARCHIVE_IOS_PATH/Q.xcarchive/Products/Library/Frameworks/Q.framework #-framework $ARCHIVE_CAT_PATH/Q.xcarchive/Products/Library/Frameworks/Q.framework #-framework $ARCHIVE_SIM_PATH/Q.xcarchive/Products/Library/Frameworks/Q.framework
xcodebuild -create-xcframework -output Q_ui.xcframework -framework $ARCHIVE_IOS_PATH/Q_ui.xcarchive/Products/Library/Frameworks/Q_ui.framework #-framework $ARCHIVE_CAT_PATH/Q_ui.xcarchive/Products/Library/Frameworks/Q_ui.framework #-framework $ARCHIVE_SIM_PATH/Q_ui.xcarchive/Products/Library/Frameworks/Q_ui.framework

# Codesign the final xcframework (optional)
if [ ! -z "$MY_TEAM_ID" ]; then
   codesign --verbose -s $MY_TEAM_ID Q.xcframework
   codesign --verbose -s $MY_TEAM_ID Q_ui.xcframework
fi
