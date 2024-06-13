#!/bin/bash

###### BEGIN USER EDIT SECTION

# Path to the base experience wrapper
# It is assumed that a subdirectory named 'Resources' exists and any 
# NIB (XIB) files will be placed inside that.
SDK_SRC_PATH=~/code/Q.reality_SDK/modules/iOS
XW_SRC_PATH=~/code/Q.reality_SDK/samples/iOS/golf/experienceWrapper

# Path to the destination xw directory
SDK_DEST_PATH=~/code/pgatour_xw/Frameworks
XW_DEST_PATH=~/code/pgatour_xw/Sources/xw

# Target tag for committing to git
TAG=0.0.1

###### END USER EDIT SECTION

# Determine the custom module name based on the last path part of the destination
CUSTOM_MODULE_NAME=`basename $XW_DEST_PATH`

# Copy the experience wrapper, overwriting anything existing
rm -rf $XW_DEST_PATH/*
cp -r $XW_SRC_PATH/* $XW_DEST_PATH/

# Fix XIB files so that they can be loaded from a package.
sed -i.bak -e "s/customModule=\"[^\"]*\"/customModule=\"$CUSTOM_MODULE_NAME\"/g" -e 's/customModuleProvider="[^"]*"/customModuleProvider=""/g' $XW_DEST_PATH/Resources/*.xib 
rm -f $XW_DEST_PATH/Resources/*.bak

# Build the latest SDK as an xcframework
pushd $SDK_SRC_PATH
#./build_xcframework.sh
popd

# Copy the frameworks, overwriting anything existing
rm -rf $SDK_DEST_PATH/*
cp -r $SDK_SRC_PATH/*.xcframework $SDK_DEST_PATH/

# Commit changes
pushd $XW_DEST_PATH
git add .
git commit -m "Changes for version $TAG"
git tag -d $TAG
git tag -a $TAG -m "v$TAG"
git push
git push -f --tags
popd
